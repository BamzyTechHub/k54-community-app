import '../models/post_model.dart';

class ApiService {
  // Simulated API data (temporary)
  Future<List<Post>> getPosts() async {
    // Simulate network loading
    await Future.delayed(const Duration(seconds: 2));

    return [
      Post(
        id: "1",
        username: "Daniel Uti",
        profession: "Freelancer, Travel Blogger",
        profileImage:
            "https://randomuser.me/api/portraits/men/1.jpg",
        caption:
            "I recently went on a hiking trip with a group of friends and family to the Himalayas. The views were beautiful and I will forever cherish these memories.",
        postImage:
            "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b",
        likes: 254,
        comments: 45,
        shares: 18,
      ),

      Post(
        id: "2",
        username: "Tanya Alive",
        profession: "Freelancer, Travel Blogger",
        profileImage:
            "https://randomuser.me/api/portraits/women/2.jpg",
        caption:
            "Today’s trip was amazing! I explored new places, met wonderful people, and captured unforgettable moments.",
        postImage:
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
        likes: 321,
        comments: 87,
        shares: 26,
      ),

      Post(
        id: "3",
        username: "Michael Brown",
        profession: "Adventure Lover",
        profileImage:
            "https://randomuser.me/api/portraits/men/3.jpg",
        caption:
            "Nature always has a way of refreshing the soul. Another beautiful journey completed today.",
        postImage:
            "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
        likes: 180,
        comments: 34,
        shares: 12,
      ),
    ];
  }
}