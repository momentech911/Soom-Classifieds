/// The 19 SOOM routes, exactly as frozen in the PRD.
///
/// **19 routes only.** Reusable sheets, dialogs, filter panels and empty
/// states are *not* routes — they are widgets shown within one of these.
/// Adding a route means changing the PRD first.
///
/// Names are used for `goNamed`/`pushNamed`; paths are the URL structure.
/// Keep the two in sync and never hardcode a path string at a call site.
enum AppRoute {
  // ---- 1-4: entry and auth -------------------------------------------
  /// 1. Bootstrap / System Gate — version check, first run, session restore.
  bootstrap('bootstrap', '/'),

  /// 2. Phone Login — fixed +974, 8 local digits.
  phoneLogin('phoneLogin', '/login'),

  /// 3. OTP Verification.
  otpVerification('otpVerification', '/login/otp'),

  /// 4. Profile Completion — name required, area optional.
  profileCompletion('profileCompletion', '/profile/complete'),

  // ---- 5-8: browse (guest-accessible) --------------------------------
  /// 5. Home.
  home('home', '/home'),

  /// 6. Explore / Results — search, filters.
  explore('explore', '/explore'),

  /// 7. Advertisement Details.
  advertisementDetails('advertisementDetails', '/ad/:adId'),

  /// 8. Media Viewer — full-screen image gallery.
  mediaViewer('mediaViewer', '/ad/:adId/media'),

  // ---- 9-10: selling --------------------------------------------------
  /// 9. Create / Edit Advertisement — the 5-step wizard.
  createEditAdvertisement('createEditAdvertisement', '/post'),

  /// 10. My Ads.
  myAds('myAds', '/my-ads'),

  // ---- 11-14: engagement ----------------------------------------------
  /// 11. Favorites.
  favorites('favorites', '/favorites'),

  /// 12. Conversations.
  conversations('conversations', '/chats'),

  /// 13. Chat — one conversation (buyer + seller + ad).
  chat('chat', '/chats/:conversationId'),

  /// 14. Notifications.
  notifications('notifications', '/notifications'),

  // ---- 15-19: profile, settings, content -------------------------------
  /// 15. My Profile.
  myProfile('myProfile', '/profile'),

  /// 16. Edit Profile.
  editProfile('editProfile', '/profile/edit'),

  /// 17. Public Seller Profile.
  sellerProfile('sellerProfile', '/seller/:sellerId'),

  /// 18. Settings.
  settings('settings', '/settings'),

  /// 19. Content Viewer — help, FAQ, legal.
  contentViewer('contentViewer', '/content/:slug');

  const AppRoute(this.routeName, this.path);

  /// Name used with `goNamed` / `pushNamed`.
  final String routeName;

  /// URL path pattern, including any `:params`.
  final String path;
}

/// Routes a signed-out user may not reach.
///
/// Guest browsing stays open — home, explore, ad details, media viewer, seller
/// profiles and content are all public. Posting, favouriting, chatting,
/// reporting and account management require a session.
const Set<AppRoute> protectedRoutes = <AppRoute>{
  AppRoute.profileCompletion,
  AppRoute.createEditAdvertisement,
  AppRoute.myAds,
  AppRoute.favorites,
  AppRoute.conversations,
  AppRoute.chat,
  AppRoute.notifications,
  AppRoute.myProfile,
  AppRoute.editProfile,
  AppRoute.settings,
};

/// Routes that make up the bottom navigation shell.
const List<AppRoute> shellRoutes = <AppRoute>[
  AppRoute.home,
  AppRoute.explore,
  AppRoute.createEditAdvertisement,
  AppRoute.conversations,
  AppRoute.myProfile,
];
