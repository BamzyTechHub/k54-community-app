import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                 CircleAvatar(
  radius: 24,
  backgroundColor: Colors.grey.shade200,
  backgroundImage: post.profileImage.isNotEmpty
      ? CachedNetworkImageProvider(post.profileImage)
      : null,
  child: post.profileImage.isEmpty
      ? const Icon(Icons.person)
      : null,
),
                const SizedBox(width: 12),
              Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Text(
        post.username,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),

      const SizedBox(height: 3),

      Row(
        children: [

          if (post.profession.isNotEmpty)

            Flexible(
              child: Text(
                post.profession,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(width: 6),

          Text(
            post.time.isEmpty
                ? post.createdAt.toString().substring(0,10)
                : post.time,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),

          const SizedBox(width: 5),

          Icon(
            post.privacy == "public"
                ? Icons.public
                : Icons.lock_outline,
            size: 14,
            color: Colors.grey,
          ),
        ],
      ),
    ],
  ),
),

PopupMenuButton(
  icon: const Icon(Icons.more_horiz),
  itemBuilder: (_) => const [
    PopupMenuItem(
      value: "report",
      child: Text("Report"),
    ),
  ],
),
              ],
            ),

            const SizedBox(height: 15),

            Html(
  data: post.caption,
  style: {
    "body": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      fontSize: FontSize(15),
      lineHeight: const LineHeight(1.5),
    ),
    "p": Style(
      margin: Margins.only(bottom: 10),
    ),
  },
),

            if (post.postImage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(15),
                  child:  CachedNetworkImage(
  imageUrl: post.postImage,
  width: double.infinity,
  fit: BoxFit.cover,

  placeholder: (_,__) => Container(
    height: 250,
    alignment: Alignment.center,
    child: const CircularProgressIndicator(),
  ),

  errorWidget: (_,__,___) =>
      const SizedBox.shrink(),
),
                ),
              ),

            const SizedBox(height: 18),
            const Divider(height: 28),

          Row(
  children: [
    Expanded(
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.favorite_border),
        label: Text(post.likes.toString()),
      ),
    ),
    Expanded(
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(post.comments.toString()),
      ),
    ),
    Expanded(
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.share_outlined),
        label: Text(post.shares.toString()),
      ),
    ),
  ],
),
          ],
        ),
      ),
    );
  }
}