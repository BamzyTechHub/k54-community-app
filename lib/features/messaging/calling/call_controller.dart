import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart' as livekit;

import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';

enum CallStatus { connecting, ringing, connected, ended, failed }

/// Owns one call's full lifecycle: `callCreate` -> connect to the real
/// LiveKit room (`video-cloud.better-messages.com`, confirmed live
/// 2026-07-21 - see MessagingRepository.startCall's doc comment) ->
/// `callStarted` once the other side actually joins -> a periodic
/// `callUsage` heartbeat while connected -> `callMissed` if the other
/// side never joins/the caller cancels first, or a clean disconnect if
/// the call did connect and either side hangs up.
///
/// No confirmed REST action exists for "call ended normally" (only
/// callCreate/callStarted/callUsage/callMissed were ever captured) - the
/// real site's own server-side almost certainly finalizes a connected
/// call from the last callUsage duration once the LiveKit room empties,
/// not from a dedicated end-call request, so this doesn't invent one.
///
/// `video-cloud.better-messages.com` is inferred to be a standard LiveKit
/// deployment (not just informed by the host name - the callCreate JWT's
/// own grant shape, `video.roomJoin`/`canPublish`/`canSubscribe`/
/// `roomConfig.maxParticipants`, is LiveKit's own native token schema,
/// not a custom one) - reachable via `wss://` using the official
/// livekit_client SDK's own signaling, not the browser's
/// `/rtc/v1/validate` REST call (that's specific to Better Messages' own
/// web-side wrapper, not something this app's SDK-based client needs to
/// replicate). This could not be end-to-end verified against a second
/// live participant in this pass - if the initial connect fails, this
/// URL/scheme is the first thing to re-check.
class CallController extends ChangeNotifier {
  CallController({
    required this.threadId,
    required this.otherUserName,
    required this.isVideo,
  });

  final String threadId;
  final String otherUserName;
  final bool isVideo;

  final MessagingRepository _repo = MessagingRepository.instance;
  final livekit.Room room = livekit.Room();

  static const _liveKitUrl = "wss://video-cloud.better-messages.com";
  static const _usageInterval = Duration(seconds: 10);
  static const _ringTimeout = Duration(seconds: 45);

  CallStatus status = CallStatus.connecting;
  String? errorMessage;
  String? _messageId;
  bool _otherSideJoined = false;
  DateTime? _connectedAt;

  Timer? _usageTimer;
  Timer? _ringTimeoutTimer;
  Timer? _ringFeedbackTimer;
  livekit.EventsListener<livekit.RoomEvent>? _listener;

  /// Real ringback/dialing audio assets aren't available (no confirmed
  /// site URL for them, and this app doesn't ship its own) - a silent
  /// call screen was direct tester feedback ("the silence is confusing,
  /// the user doesn't know if the call is going through"). A periodic
  /// system click + haptic pulse gives genuine, real feedback that
  /// something is happening without fabricating an audio file.
  void _startRingFeedback() {
    _ringFeedbackTimer?.cancel();
    _ringFeedbackTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    });
  }

  void _stopRingFeedback() {
    _ringFeedbackTimer?.cancel();
    _ringFeedbackTimer = null;
  }

  int get durationSeconds =>
      _connectedAt == null ? 0 : DateTime.now().difference(_connectedAt!).inSeconds;

  Future<void> start() async {
    try {
      final session = await _repo.startCall(threadId: threadId, type: isVideo ? "video" : "audio");
      _messageId = session.messageId;

      _listener = room.createListener();
      _listener!
        ..on<livekit.ParticipantConnectedEvent>((_) => _onOtherSideJoined())
        ..on<livekit.RoomDisconnectedEvent>((_) => _onRoomDisconnected());

      status = CallStatus.ringing;
      notifyListeners();
      _startRingFeedback();

      await room.connect(_liveKitUrl, session.token);
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (isVideo) {
        await room.localParticipant?.setCameraEnabled(true);
      }

      // If nobody joins within the ring window, treat it as a missed call
      // rather than ringing forever - the real site's own UI has some
      // equivalent timeout, though its exact duration wasn't confirmed
      // live, so this value is a reasonable estimate, not a captured one.
      _ringTimeoutTimer = Timer(_ringTimeout, () {
        if (!_otherSideJoined) hangUp();
      });
    } catch (e) {
      status = CallStatus.failed;
      errorMessage = e.toString();
      _stopRingFeedback();
      notifyListeners();
    }
  }

  void _onOtherSideJoined() {
    if (_otherSideJoined) return;
    _otherSideJoined = true;
    _connectedAt = DateTime.now();
    status = CallStatus.connected;
    _ringTimeoutTimer?.cancel();
    _stopRingFeedback();
    notifyListeners();

    final messageId = _messageId;
    if (messageId != null) {
      _repo.markCallStarted(threadId: threadId, messageId: messageId, type: isVideo ? "video" : "audio");
    }

    _usageTimer = Timer.periodic(_usageInterval, (_) => _sendUsage());
  }

  void _sendUsage() {
    final messageId = _messageId;
    if (messageId == null || status != CallStatus.connected) return;
    // Real per-track byte counters aren't exposed as a simple synchronous
    // getter on livekit_client's public API - duration (the figure that
    // actually matters for the call log/history) is tracked accurately;
    // bytes are sent as 0 rather than a fabricated number.
    _repo.sendCallUsage(threadId: threadId, messageId: messageId, durationSeconds: durationSeconds);
  }

  void _onRoomDisconnected() {
    if (status == CallStatus.ended) return;
    status = CallStatus.ended;
    _usageTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    _stopRingFeedback();
    notifyListeners();
  }

  /// Ends the call - `callMissed` if the other side never joined (an
  /// outgoing call the caller cancelled, or nobody answered), otherwise
  /// just disconnects from the room (see class doc for why no "ended"
  /// REST call exists to send here).
  Future<void> hangUp() async {
    if (status == CallStatus.ended) return;
    final messageId = _messageId;
    if (!_otherSideJoined && messageId != null) {
      await _repo.markCallMissed(
        threadId: threadId,
        messageId: messageId,
        type: isVideo ? "video" : "audio",
        durationSeconds: 0,
      );
    }
    _usageTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    _stopRingFeedback();
    status = CallStatus.ended;
    notifyListeners();
    await room.disconnect();
  }

  Future<void> toggleMute() async {
    final enabled = room.localParticipant?.isMicrophoneEnabled() ?? false;
    await room.localParticipant?.setMicrophoneEnabled(!enabled);
    notifyListeners();
  }

  bool get isMuted => !(room.localParticipant?.isMicrophoneEnabled() ?? true);

  @override
  void dispose() {
    _usageTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    _stopRingFeedback();
    _listener?.dispose();
    room.dispose();
    super.dispose();
  }
}
