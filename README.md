<div align="center">

<br/>

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Hive-FFB300?style=for-the-badge&logo=hive&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/TMDB_API-01B4E4?style=for-the-badge&logo=themoviedatabase&logoColor=white" />

<br/><br/>

</div>

# CineVault 🎬

A beautifully crafted, feature-rich Flutter movie and TV show discovery app powered by the TMDB API. CineVault offers a cinematic dark-theme experience with Firebase authentication, offline-first architecture, wishlists, cast details, genre browsing, and advanced search — all in one polished package.

---

## Features

**Authentication & Profile**
- Email/password sign-up with email verification flow
- Secure sign-in with Firebase Authentication
- Profile setup with 25 customizable avatars
- Edit profile — change name, avatar, email, and password
- Auto-restore profile and wishlist data on reinstall via Firestore

**Movies**
- Hero carousel of Now Playing movies with auto-play
- Sections: Popular Now, Top Rated, Coming Soon
- Full movie detail page with trailer playback (YouTube), cast, and similar movies
- Wishlist add/remove with confirmation dialog

**TV Shows**
- Airing Today carousel with teal accent theme
- Sections: Popular Shows, Top Rated, On The Air
- Full TV detail page with trailer, cast, and similar shows
- Wishlist support identical to movies

**Search & Discovery**
- Dedicated movie and TV search screens
- Advanced filter drawer: sort, genres, release date range, rating range, vote count, runtime, language/country
- Active filter count badge

**Genres**
- Movie and TV genre grids with per-genre color accents
- Browse all movies/shows within any genre
- "All" shortcut for genre-agnostic browsing

**See All**
- Paginated grid screens for Popular, Top Rated, Coming Soon (movies) and Popular, Top Rated, On The Air (TV)
- Inline search within each list

**Cast**
- Horizontal cast row on every detail screen
- Cast detail screen: biography (expandable), stats (age, popularity, gender), filmography grid with navigation to movie details
- Hero animation on cast avatar

**Wishlist**
- Tabbed screen for Movies and TV Shows
- Inline search, delete with confirmation
- Synced to Firestore and cached locally in Hive

**Profile**
- Purple-gradient profile header
- Edit Profile → Personal Details, Email, Password sub-screens
- Sign out with confirmation dialog

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Auth & Database | Firebase Authentication + Cloud Firestore |
| Local Cache | Hive (hive_flutter) |
| Movie/TV Data | TMDB API v3 |
| Video Playback | youtube_player_flutter |
| Image Loading | cached_network_image |
| Carousel | flutter_carousel_widget |
| HTTP | http |

---

## Architecture

```
lib/
├── constants/
│   └── constants.dart          # API base URLs and endpoint keys
├── data/
│   ├── firebase_service.dart   # Firebase Auth + Firestore operations
│   ├── hive_service.dart       # Local cache: profile + wishlist
│   └── wishlist_service.dart   # Unified wishlist (Hive + Firestore sync)
├── model/
│   ├── movie_model.dart
│   ├── tv_model.dart
│   ├── cast_model.dart
│   └── video_model.dart
├── service/
│   └── api_service.dart        # TMDB API calls
└── ui/
    ├── login_page.dart
    ├── signup_page.dart (sign-up + email verification)
    ├── setup_profile_screen.dart
    ├── home.dart               # Bottom nav shell (Movies, TV, Wishlist, Profile)
    ├── movie/
    │   ├── movie_page.dart
    │   ├── movies_category.dart
    │   ├── movie_details.dart
    │   └── components/
    │       ├── movie_carousel.dart
    │       └── movie_list_item.dart
    ├── tv/
    │   ├── tv_page.dart
    │   ├── tv_category.dart
    │   ├── tv_details.dart
    │   └── components/
    │       ├── tv_carusel.dart
    │       └── tv_list_item.dart
    ├── components/
    │   ├── cast_page.dart
    │   └── cast_list_item.dart
    ├── wishlist/
    │   └── wishlist_screen.dart
    ├── profile/
    │   ├── profile_screen.dart
    │   ├── edit_profile_screen.dart
    │   ├── change_personal_details_screen.dart
    │   ├── change_email_screen.dart
    │   └── change_password_screen.dart
    ├── genres/
    │   ├── movie_genres_screen.dart
    │   ├── movie_genre_details_screen.dart
    │   ├── movie_all_genres_details_screen.dart
    │   ├── tv_genres_screen.dart
    │   ├── tv_genre_details_screen.dart
    │   └── tv_all_genres_details_screen.dart
    ├── search/
    │   ├── movie_search_screen.dart
    │   └── tv_search_screen.dart
    ├── see_all/
    │   ├── see_all_movies_screen.dart
    │   └── tv_see_all_screen.dart
    └── cast_detail_screen.dart
```

**Data Flow**

```
App Launch
    └── FirebaseAuth.authStateChanges()
            ├── Not logged in  →  LoginPage
            └── Logged in
                    ├── Hive has data  →  HomePage (fast path)
                    └── Hive empty     →  Firestore fetch
                                               ├── Profile found  →  Hive restore  →  HomePage
                                               └── No profile     →  SetupProfileScreen
```

**Wishlist Sync**

Every wishlist add/remove writes to Hive immediately (instant UI), then fires a Firestore update in the background (fire-and-forget). On a fresh install the full wishlist is restored from Firestore before navigating to HomePage.

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x
- A Firebase project with **Authentication** (Email/Password) and **Firestore** enabled
- A TMDB API key (v3)

### Setup

1. **Clone the repository**

```bash
git clone https://github.com/TanvirAhmedCSE/cinevault-movie-and-tv-show-streaming-app.git
cd cinevault-movie-and-tv-show-streaming-app
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Firebase setup**

   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Email/Password authentication
   - Enable Cloud Firestore
   - Download `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS) and place them in the correct platform directories
   - Run `flutterfire configure` or manually add `firebase_options.dart`

4. **TMDB API key**

   The API key is currently embedded in `api_service.dart`. For production use, move it to a `.env` file or use Flutter's `--dart-define` flag:

   ```bash
   flutter run --dart-define=TMDB_API_KEY=your_key_here
   ```

5. **Avatar assets**

   Place your avatar images in `assets/images/`:
   - `avatar_null_profile_picture.png` — default avatar
   - `avatar_profile_picture_1.png` through `avatar_profile_picture_24.png` — 24 selectable avatars

   Declare them in `pubspec.yaml`:

   ```yaml
   flutter:
     assets:
       - assets/images/
   ```

6. **Run the app**

```bash
flutter run
```

---

## Key Dependencies

```yaml
dependencies:
  http: ^1.6.0
  flutter_rating_bar: ^4.0.1
  cached_network_image: ^3.2.3
  flutter_carousel_widget: ^2.1.1
  url_launcher: ^6.1.10
  youtube_player_flutter: ^9.0.2
  google_fonts: ^6.2.1
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  hive_flutter: ^1.1.0
```

---

## Firestore Rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own profile
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

---

## Screenshots

<table>
  <tr>
    <td align="center"><img src="app screenshots/1.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2a.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/3.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/4.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/5.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/6.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/7.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/8.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/9.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/11.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/12.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/13.jpg" width="220"/><br/><sub><b>Search Movies(More are loading)</b></sub></td>
    <td align="center"><img src="app screenshots/14.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/15.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/16.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/17.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/18.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/19.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/20.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/21.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/22.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/23.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/24.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/25.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/26.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/27.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/28.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/29.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/30.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/31.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/32.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/33.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/34.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/35.jpg" width="220"/><br/><sub><b>Search TV Shows(More are loading)</b></sub></td>
    <td align="center"><img src="app screenshots/36.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/37.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/38.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/39.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/40.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/41.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/42.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/43.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/44.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/45.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/46.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/47.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/48.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/49.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/50.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/51.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/52.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/53.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/54.jpg" width="220"/><br/><sub><b>Changed Name</b></sub></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/55.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/56.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/57.jpg" width="220"/><br/><sub><b>Login with New Email</b></sub></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/58.jpg" width="220"/><br/><sub><b>Changed Email</b></sub></td>
    <td align="center"><img src="app screenshots/59.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/60.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"></td>
    <td align="center"></td>
  </tr>
</table>

---

## Security Notes

- The TMDB API key in this repository is for development/demonstration purposes. **Replace it with your own key** before deploying or publishing.
- Firebase security rules should be configured to restrict Firestore reads/writes to authenticated users only. **Get your own firebase_options.dart, google-services.json and firebase.json files.**

---

## Credits

- Movie and TV data provided by [The Movie Database (TMDB)](https://www.themoviedb.org/)
- This product uses the TMDB API but is not endorsed or certified by TMDB.

---

## License

This project is open-source and available under the [MIT License](LICENSE).

---

<div align="center">

Made with ❤️ and Flutter by **[TanvirAhmedCSE](https://github.com/TanvirAhmedCSE)**

*If you like this project, give it a ⭐ on GitHub!*

</div>
