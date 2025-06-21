// Social Manager voor vrienden systeem en sociale interacties
// Deze class beheert vriendschappen, likes, comments en sociale activiteiten
import Foundation

// Vriendschap model
struct Friendship: Codable, Identifiable {
    let id: String
    let userId: String // Aanvrager
    let friendId: String // Ontvanger
    let friendDisplayName: String
    let status: FriendshipStatus
    let requestedAt: Date
    let acceptedAt: Date?
    
    init(userId: String, friendId: String, friendDisplayName: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.friendId = friendId
        self.friendDisplayName = friendDisplayName
        self.status = .pending
        self.requestedAt = Date()
        self.acceptedAt = nil
    }
    
    // Update voor geaccepteerde vriendschap
    init(id: String, userId: String, friendId: String, friendDisplayName: String, status: FriendshipStatus, requestedAt: Date, acceptedAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.friendId = friendId
        self.friendDisplayName = friendDisplayName
        self.status = status
        self.requestedAt = requestedAt
        self.acceptedAt = acceptedAt
    }
}

// Vriendschap status
enum FriendshipStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case blocked = "blocked"
}

// Like model voor ratings
struct RatingLike: Codable, Identifiable {
    let id: String
    let ratingId: String
    let userId: String
    let userDisplayName: String
    let likedAt: Date
    
    init(ratingId: String, userId: String, userDisplayName: String) {
        self.id = UUID().uuidString
        self.ratingId = ratingId
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.likedAt = Date()
    }
}

// Comment model voor ratings
struct RatingComment: Codable, Identifiable {
    let id: String
    let ratingId: String
    let userId: String
    let userDisplayName: String
    let comment: String
    let commentedAt: Date
    
    init(ratingId: String, userId: String, userDisplayName: String, comment: String) {
        self.id = UUID().uuidString
        self.ratingId = ratingId
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.comment = comment
        self.commentedAt = Date()
    }
}

// Activiteit model voor feed
struct SocialActivity: Codable, Identifiable {
    let id: String
    let userId: String
    let userDisplayName: String
    let activityType: ActivityType
    let albumId: String?
    let albumName: String?
    let artistName: String?
    let rating: Int?
    let review: String?
    let activityDate: Date
    
    init(userId: String, userDisplayName: String, activityType: ActivityType, albumId: String? = nil, albumName: String? = nil, artistName: String? = nil, rating: Int? = nil, review: String? = nil) {
        self.id = UUID().uuidString
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.activityType = activityType
        self.albumId = albumId
        self.albumName = albumName
        self.artistName = artistName
        self.rating = rating
        self.review = review
        self.activityDate = Date()
    }
}

// Activiteit types
enum ActivityType: String, Codable {
    case newRating = "new_rating"
    case newFriend = "new_friend"
    case playlistCreated = "playlist_created"
    case highRating = "high_rating" // 5 sterren rating
}

// Social Manager class
class SocialManager: ObservableObject {
    
    // Singleton instance
    static let shared = SocialManager()
    
    // UserDefaults keys
    private let friendshipsKey = "friendships"
    private let likesKey = "rating_likes"
    private let commentsKey = "rating_comments"
    private let activitiesKey = "social_activities"
    
    // Published properties
    @Published var friends: [Friendship] = []
    @Published var pendingRequests: [Friendship] = []
    @Published var sentRequests: [Friendship] = []
    @Published var socialFeed: [SocialActivity] = []
    @Published var ratingLikes: [String: [RatingLike]] = [:] // RatingId -> Likes
    @Published var ratingComments: [String: [RatingComment]] = [:] // RatingId -> Comments
    
    // Reference to other managers
    private let storageManager = LocalStorageManager.shared
    
    private init() {
        loadSocialData()
    }
    
    // MARK: - Friendship Management
    
    // Verstuur vriendschapsverzoek
    func sendFriendRequest(to friendId: String, friendDisplayName: String) -> Bool {
        guard let currentUser = storageManager.currentUser else { return false }
        guard friendId != currentUser.id else { return false } // Kan niet jezelf toevoegen
        
        // Check of er al een vriendschap bestaat
        let allFriendships = getAllFriendships()
        let existingFriendship = allFriendships.first { friendship in
            (friendship.userId == currentUser.id && friendship.friendId == friendId) ||
            (friendship.userId == friendId && friendship.friendId == currentUser.id)
        }
        
        if existingFriendship != nil {
            return false // Vriendschap bestaat al
        }
        
        // Maak nieuwe vriendschap aan
        let friendship = Friendship(userId: currentUser.id, friendId: friendId, friendDisplayName: friendDisplayName)
        
        var friendships = allFriendships
        friendships.append(friendship)
        saveFriendships(friendships)
        
        // Voeg activiteit toe
        createActivity(activityType: .newFriend, userId: currentUser.id, userDisplayName: currentUser.displayName)
        
        DispatchQueue.main.async {
            self.loadFriendships()
        }
        
        return true
    }
    
    // Accepteer vriendschapsverzoek
    func acceptFriendRequest(_ friendshipId: String) -> Bool {
        var allFriendships = getAllFriendships()
        
        guard let index = allFriendships.firstIndex(where: { $0.id == friendshipId }) else {
            return false
        }
        
        let friendship = allFriendships[index]
        let updatedFriendship = Friendship(
            id: friendship.id,
            userId: friendship.userId,
            friendId: friendship.friendId,
            friendDisplayName: friendship.friendDisplayName,
            status: .accepted,
            requestedAt: friendship.requestedAt,
            acceptedAt: Date()
        )
        
        allFriendships[index] = updatedFriendship
        saveFriendships(allFriendships)
        
        DispatchQueue.main.async {
            self.loadFriendships()
        }
        
        return true
    }
    
    // Weiger vriendschapsverzoek
    func declineFriendRequest(_ friendshipId: String) -> Bool {
        var allFriendships = getAllFriendships()
        allFriendships.removeAll { $0.id == friendshipId }
        saveFriendships(allFriendships)
        
        DispatchQueue.main.async {
            self.loadFriendships()
        }
        
        return true
    }
    
    // Verwijder vriend
    func removeFriend(_ friendshipId: String) -> Bool {
        return declineFriendRequest(friendshipId)
    }
    
    // MARK: - Social Interactions
    
    // Like een rating
    func likeRating(ratingId: String, userId: String, userDisplayName: String) -> Bool {
        // Check of gebruiker rating al heeft geliked
        let likes = getRatingLikes(for: ratingId)
        if likes.contains(where: { $0.userId == userId }) {
            return false // Al geliked
        }
        
        let like = RatingLike(ratingId: ratingId, userId: userId, userDisplayName: userDisplayName)
        
        var allLikes = getAllLikes()
        allLikes.append(like)
        saveLikes(allLikes)
        
        DispatchQueue.main.async {
            self.loadLikes()
        }
        
        return true
    }
    
    // Unlike een rating
    func unlikeRating(ratingId: String, userId: String) -> Bool {
        var allLikes = getAllLikes()
        allLikes.removeAll { $0.ratingId == ratingId && $0.userId == userId }
        saveLikes(allLikes)
        
        DispatchQueue.main.async {
            self.loadLikes()
        }
        
        return true
    }
    
    // Voeg comment toe aan rating
    func addComment(to ratingId: String, userId: String, userDisplayName: String, comment: String) -> Bool {
        guard !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        
        let ratingComment = RatingComment(
            ratingId: ratingId,
            userId: userId,
            userDisplayName: userDisplayName,
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        var allComments = getAllComments()
        allComments.append(ratingComment)
        saveComments(allComments)
        
        DispatchQueue.main.async {
            self.loadComments()
        }
        
        return true
    }
    
    // Verwijder comment
    func removeComment(_ commentId: String, userId: String) -> Bool {
        var allComments = getAllComments()
        allComments.removeAll { $0.id == commentId && $0.userId == userId }
        saveComments(allComments)
        
        DispatchQueue.main.async {
            self.loadComments()
        }
        
        return true
    }
    
    // MARK: - Activity Feed
    
    // Maak nieuwe activiteit
    func createActivity(activityType: ActivityType, userId: String, userDisplayName: String, albumId: String? = nil, albumName: String? = nil, artistName: String? = nil, rating: Int? = nil, review: String? = nil) {
        let activity = SocialActivity(
            userId: userId,
            userDisplayName: userDisplayName,
            activityType: activityType,
            albumId: albumId,
            albumName: albumName,
            artistName: artistName,
            rating: rating,
            review: review
        )
        
        var allActivities = getAllActivities()
        allActivities.append(activity)
        
        // Houd alleen de laatste 100 activiteiten
        if allActivities.count > 100 {
            allActivities = Array(allActivities.suffix(100))
        }
        
        saveActivities(allActivities)
        
        DispatchQueue.main.async {
            self.loadSocialFeed()
        }
    }
    
    // Laad sociale feed (alleen vrienden en eigen activiteiten)
    func loadSocialFeed() {
        guard let currentUser = storageManager.currentUser else { return }
        
        let allActivities = getAllActivities()
        let friendIds = friends.map { $0.friendId } + friends.map { $0.userId }
        let relevantActivities = allActivities.filter { activity in
            activity.userId == currentUser.id || friendIds.contains(activity.userId)
        }
        
        DispatchQueue.main.async {
            self.socialFeed = relevantActivities.sorted { $0.activityDate > $1.activityDate }
        }
    }
    
    // MARK: - Data Loading
    
    // Laad alle sociale data
    func loadSocialData() {
        loadFriendships()
        loadLikes()
        loadComments()
        loadSocialFeed()
    }
    
    // Laad vriendschappen
    private func loadFriendships() {
        guard let currentUser = storageManager.currentUser else { return }
        
        let allFriendships = getAllFriendships()
        
        DispatchQueue.main.async {
            // Vrienden (geaccepteerde vriendschappen)
            self.friends = allFriendships.filter { friendship in
                (friendship.userId == currentUser.id || friendship.friendId == currentUser.id) &&
                friendship.status == .accepted
            }
            
            // Ontvangen verzoeken
            self.pendingRequests = allFriendships.filter { friendship in
                friendship.friendId == currentUser.id && friendship.status == .pending
            }
            
            // Verstuurde verzoeken
            self.sentRequests = allFriendships.filter { friendship in
                friendship.userId == currentUser.id && friendship.status == .pending
            }
        }
    }
    
    // Laad likes
    private func loadLikes() {
        let allLikes = getAllLikes()
        var likesByRating: [String: [RatingLike]] = [:]
        
        for like in allLikes {
            likesByRating[like.ratingId, default: []].append(like)
        }
        
        DispatchQueue.main.async {
            self.ratingLikes = likesByRating
        }
    }
    
    // Laad comments
    private func loadComments() {
        let allComments = getAllComments()
        var commentsByRating: [String: [RatingComment]] = [:]
        
        for comment in allComments {
            commentsByRating[comment.ratingId, default: []].append(comment)
        }
        
        DispatchQueue.main.async {
            self.ratingComments = commentsByRating
        }
    }
    
    // MARK: - Helper Functions
    
    // Haal likes op voor een rating
    func getRatingLikes(for ratingId: String) -> [RatingLike] {
        return ratingLikes[ratingId] ?? []
    }
    
    // Haal comments op voor een rating
    func getRatingComments(for ratingId: String) -> [RatingComment] {
        return ratingComments[ratingId] ?? []
    }
    
    // Check of gebruiker rating heeft geliked
    func hasUserLikedRating(ratingId: String, userId: String) -> Bool {
        return getRatingLikes(for: ratingId).contains { $0.userId == userId }
    }
    
    // Haal aantal likes op voor rating
    func getLikeCount(for ratingId: String) -> Int {
        return getRatingLikes(for: ratingId).count
    }
    
    // Haal aantal comments op voor rating
    func getCommentCount(for ratingId: String) -> Int {
        return getRatingComments(for: ratingId).count
    }
    
    // Check of gebruikers vrienden zijn
    func areFriends(userId1: String, userId2: String) -> Bool {
        let allFriendships = getAllFriendships()
        return allFriendships.contains { friendship in
            ((friendship.userId == userId1 && friendship.friendId == userId2) ||
             (friendship.userId == userId2 && friendship.friendId == userId1)) &&
            friendship.status == .accepted
        }
    }
    
    // MARK: - Data Persistence
    
    private func getAllFriendships() -> [Friendship] {
        guard let data = UserDefaults.standard.data(forKey: friendshipsKey),
              let friendships = try? JSONDecoder().decode([Friendship].self, from: data) else {
            return []
        }
        return friendships
    }
    
    private func saveFriendships(_ friendships: [Friendship]) {
        if let data = try? JSONEncoder().encode(friendships) {
            UserDefaults.standard.set(data, forKey: friendshipsKey)
        }
    }
    
    private func getAllLikes() -> [RatingLike] {
        guard let data = UserDefaults.standard.data(forKey: likesKey),
              let likes = try? JSONDecoder().decode([RatingLike].self, from: data) else {
            return []
        }
        return likes
    }
    
    private func saveLikes(_ likes: [RatingLike]) {
        if let data = try? JSONEncoder().encode(likes) {
            UserDefaults.standard.set(data, forKey: likesKey)
        }
    }
    
    private func getAllComments() -> [RatingComment] {
        guard let data = UserDefaults.standard.data(forKey: commentsKey),
              let comments = try? JSONDecoder().decode([RatingComment].self, from: data) else {
            return []
        }
        return comments
    }
    
    private func saveComments(_ comments: [RatingComment]) {
        if let data = try? JSONEncoder().encode(comments) {
            UserDefaults.standard.set(data, forKey: commentsKey)
        }
    }
    
    private func getAllActivities() -> [SocialActivity] {
        guard let data = UserDefaults.standard.data(forKey: activitiesKey),
              let activities = try? JSONDecoder().decode([SocialActivity].self, from: data) else {
            return []
        }
        return activities
    }
    
    private func saveActivities(_ activities: [SocialActivity]) {
        if let data = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(data, forKey: activitiesKey)
        }
    }
    

} 