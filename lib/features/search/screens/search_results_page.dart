import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/k54_search_field.dart';
import 'package:k54_mobile/features/search/models/search_result_model.dart';
import 'package:k54_mobile/features/search/repositories/search_repository.dart';

/// Matches the live site's own search (k54global.com/?s=) - a plain flat
/// result list with no tabs or filters (confirmed by fetching the live
/// page directly). Figma's "Search filter" frame couldn't be re-verified
/// (API rate-limited) but the website is the functional source of truth
/// here, and it genuinely has no filter UI to match.
class SearchResultsPage extends StatefulWidget {
  final String initialQuery;

  const SearchResultsPage({super.key, this.initialQuery = ""});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);
  List<SearchResult> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().isNotEmpty) _search(widget.initialQuery);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final results = await SearchRepository.instance.search(query: query.trim());
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconFor(SearchResult r) {
    switch (r.subtype) {
      case "courses":
        return Icons.school_outlined;
      case "page":
        return Icons.article_outlined;
      default:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.iconButtonBackground,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, size: 16, color: AppColors.jetBlack),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: K54SearchField(
                      controller: _controller,
                      autofocus: widget.initialQuery.isEmpty,
                      onSubmitted: _search,
                      hintText: "Search K54 Global",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_searched) {
      return Center(
        child: Text("Search for people, courses and pages", style: GoogleFonts.lato(color: Colors.grey.shade600)),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't search.\n$_error", textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: () => _search(_controller.text), child: const Text("Retry")),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(child: Text("No results for \"${_controller.text}\"", style: GoogleFonts.lato(color: Colors.grey.shade600)));
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = _results[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.groupCardBackground,
            child: Icon(_iconFor(r), color: AppColors.green, size: 20),
          ),
          title: Text(r.title, style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15)),
          subtitle: Text(r.subtype.isEmpty ? r.type : r.subtype, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
          onTap: () {
            final uri = Uri.tryParse(r.url);
            if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        );
      },
    );
  }
}
