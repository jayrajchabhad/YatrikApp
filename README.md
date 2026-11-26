# Yatrik

Flutter travel app backed by Firebase Authentication, Cloud Firestore, and
Cloud Storage. Hotel listings, room inventory, bookings, reviews, customer
profiles, and saved stays are stored in Firestore; uploaded images are stored
in Cloud Storage.

## Firebase setup for the Android demo

1. In Firebase Console, enable **Authentication → Email/Password**.
2. Enable **Storage** and create the project's default bucket. Depending on the
   Firebase plan, Storage may require a billing-enabled plan.
3. Under **Authentication → Users**, create an admin user and copy its UID.
   Keep the password private.
4. In Firestore, create `admins/{UID}` using that UID as the document ID, with
   the Boolean field `isAdmin` set to `true`.
5. Publish [`firestore.rules`](./firestore.rules) in **Firestore → Rules** and
   [`storage.rules`](./storage.rules) in **Storage → Rules**.
   The rules allow public hotel/room/review reads, admin-only catalog changes,
   and owner-only access to customer data.
6. Sign in to the app's Admin panel and manage hotels and room categories
   there. Hotel and room forms select images from the computer and upload them
   to Cloud Storage. Hotel documents use:
   - `title` (String)
   - `location` (String)
   - `rating` (Number, 0–5)
   - `price` (Number, INR per night)
   - `imageUrl` (String; optional)
   - `description`, `propertyType`, `amenities` (optional)
7. In **Room Inventory**, add at least one room category for each hotel that
   customers should be able to book, or use **Add missing rooms** to create
   starter room categories. Its rate and available units are managed separately
   from the hotel listing. Creating a booking reserves one unit; cancelling or
   completing the stay restores it.
8. Customers create accounts with the app's sign-up screen. The app writes
   their profile to `users/{uid}` and saves favourites under
   `users/{uid}/savedStays/{hotelId}`. Bookings are stored in `bookings`;
   customer reviews are stored in `reviews`.

The configured `yatrik-e2afd` project includes four demo hotels and six room
categories. Admins can use **Master of Hotels → Add demo hotels & rooms** to
add any missing demo records; deterministic document IDs prevent duplicates
and existing records are never overwritten. In **Reservations & Bookings**,
**Add sample bookings** creates an upcoming confirmed booking, a pending
booking, and a cancelled booking for Admin preview. The action is idempotent.

The app's payment choices are for presentation only. The app does not charge
customers or connect to a payment provider.

To publish the rules using the Firebase CLI instead of the Console:

```bash
firebase deploy --only firestore:rules --project=yatrik-e2afd
```

Publish both Firestore and Storage rules with:

```bash
firebase deploy --only firestore:rules,storage --project=yatrik-e2afd
```

FlutterFire configuration for this Firebase project:

```bash
firebase login
dart pub global run flutterfire_cli:flutterfire configure --project=yatrik-e2afd --platforms=android,web
```

Firebase-generated files (`lib/firebase_options.dart`,
`android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`)
are intentionally excluded from this repository. Run the FlutterFire command
above after cloning, before building the app.

Run the app locally in Chrome with `flutter run -d chrome`, or select an
Android device in Android Studio. Firebase Hosting is not required; the app
needs internet access to read and write Firestore data.
