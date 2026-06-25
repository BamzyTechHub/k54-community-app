import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Profile section
          Row(
            children: [

              CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                  post.profileImage,
                ),
              ),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    post.username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(
                    post.profession,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                ],
              ),

            ],
          ),

          const SizedBox(height: 15),


          // Caption
          Text(
            post.caption,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),


          const SizedBox(height: 15),


          // Post image
          ClipRRect(
            borderRadius: BorderRadius.circular(15),

            child: Image.network(
              post.postImage,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),


          const SizedBox(height: 15),


          // Post actions
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,

            children: [

              _actionButton(
                Icons.thumb_up_alt_outlined,
                "Like",
              ),

              _actionButton(
                Icons.mode_comment_outlined,
                "Comment",
              ),

              _actionButton(
                Icons.repeat,
                "Share",
              ),

              _actionButton(
                Icons.send_outlined,
                "Send",
              ),

            ],
          ),

        ],
      ),
    );
  }


  Widget _actionButton(
    IconData icon,
    String text,
  ) {

    return Column(
      children: [

        Icon(
          icon,
          size: 25,
          color: Colors.black87,
        ),

        const SizedBox(height: 5),

        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
          ),
        ),

      ],
    );
  }
}