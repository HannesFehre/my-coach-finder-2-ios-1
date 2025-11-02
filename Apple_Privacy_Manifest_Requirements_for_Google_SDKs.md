# Resolving ITMS-91061: Apple Privacy Manifest Requirements for Google SDKs

Your TestFlight rejection for ITMS-91061 has a straightforward fix: **update GoogleSignIn to version 7.1.0 or later, GTMAppAuth to 4.1.1+, and GTMSessionFetcher to 3.3.0+**, all of which include the required privacy manifest files. These versions were released in March 2024 specifically to comply with Apple's privacy requirements. Update your Flutter dependencies, run `pod install`, verify the privacy manifests are present, and resubmit. Expect a 24-48 hour TestFlight review turnaround.

This error emerged from Apple's comprehensive privacy enforcement that began in May 2024 and intensified through fall 2024, with stricter enforcement starting February 12, 2025 for apps adding or updating privacy-impacting SDKs. The policy requires all commonly used third-party SDKs to include PrivacyInfo.xcprivacy files that declare their data collection practices and API usage. Your three Google frameworks—GTMAppAuth, GTMSessionFetcher, and GoogleSignIn—are explicitly listed among Apple's 86 required SDKs, meaning they must bundle privacy manifests or your app faces rejection during App Store Connect processing.

## Apple's privacy manifest policy: a timeline of enforcement

Apple introduced privacy manifests at WWDC 2023 in June, presenting them as a transparency tool to help developers identify privacy practices in third-party dependencies. The policy evolved from informational warnings in fall 2023 to full enforcement beginning May 1, 2024, when apps without proper Required Reason API declarations began facing upload rejections. The enforcement timeline accelerated through 2024, with November 12 marking intensified scrutiny for Flutter and cross-platform frameworks, and **February 12, 2025 establishing the current hard deadline** where apps including privacy-impacting SDKs without manifests face automatic rejection.

Throughout fall 2023, Apple sent informational emails notifying developers about missing manifests but allowed submissions to proceed. By February 29, 2024, Apple published specific enforcement dates, and March 13 saw expanded email notifications about Required Reason API usage. The May 1, 2024 deadline made Required Reason APIs mandatory, preventing apps from uploading to App Store Connect without approved reason declarations. Currently, as of November 2025, all privacy manifest requirements are fully enforced, with ITMS-91061 errors resulting in immediate app rejection during the review process.

The policy serves multiple purposes beyond simple transparency. Apple aims to combat device fingerprinting, enforce App Tracking Transparency (ATT) compliance at the system level, secure the software supply chain through SDK signatures, and prevent unauthorized data collection. When an app declares tracking domains in its privacy manifest but the user hasn't granted ATT permission, iOS automatically blocks network requests to those domains at the system level—a powerful enforcement mechanism that makes privacy manifests more than documentation.

## Understanding privacy manifest files and their structure

Privacy manifests are XML-based property list files that **must be named exactly PrivacyInfo.xcprivacy** and placed in the app or SDK's bundle root. The file format requires four mandatory top-level keys, even if their values are empty arrays or false booleans. Missing any of these keys causes validation failures during Apple's review process.

The first key, **NSPrivacyTracking**, is a boolean indicating whether the app or SDK uses data for "tracking" as defined under App Tracking Transparency. When set to true, you must provide at least one domain in the companion NSPrivacyTrackingDomains key. The second key, **NSPrivacyTrackingDomains**, is an array of strings listing internet domains that the app connects to for tracking purposes. iOS enforces this at the system level: if a user hasn't granted tracking permission, network requests to these domains automatically fail.

The third key, **NSPrivacyCollectedDataTypes**, describes all data types the app or SDK collects through an array of dictionaries. Each dictionary requires four sub-keys: NSPrivacyCollectedDataType (the type of data like contact info or device ID), NSPrivacyCollectedDataTypeLinked (boolean for whether data is linked to user identity), NSPrivacyCollectedDataTypeTracking (boolean for tracking usage), and NSPrivacyCollectedDataTypePurposes (an array of purposes like app functionality or analytics). The data collection categories span twelve types including Contact Info, Location, Identifiers, Financial Info, Health & Fitness, Usage Data, and Diagnostics.

The fourth key, **NSPrivacyAccessedAPITypes**, is critical for avoiding ITMS-91053 errors and declares Required Reason APIs accessed by the app or SDK. This array of dictionaries requires two sub-keys per API: NSPrivacyAccessedAPIType (the API category like UserDefaults or FileTimestamp) and NSPrivacyAccessedAPITypeReasons (an array of approved reason codes from Apple's list). Apple defines five Required Reason API categories: UserDefaults APIs, File timestamp APIs, System boot time APIs, Disk space APIs, and Active keyboard APIs. Each category has specific approved reason codes like CA92.1 for UserDefaults or E174.1 for disk space checks.

You create privacy manifest files in Xcode 15 or later by choosing File → New File, scrolling to the Resource section, and selecting "App Privacy File" type. The file must be added to the target's bundle resources in Build Phases, which is the most commonly missed step causing "Archive does not contain any PrivacyInfo.xcprivacy files" errors. Even if the file exists in your project navigator, it won't be included in the IPA archive unless target membership is properly configured.

## The complete list of required third-party SDKs

Apple maintains an official list of **86 commonly used third-party SDKs** at developer.apple.com/support/third-party-SDK-requirements that must include privacy manifests and signatures when used as binary dependencies. This list includes major frameworks across multiple categories: networking libraries (AFNetworking, Alamofire), authentication SDKs (AppAuth, GoogleSignIn, GTMAppAuth), session management (GTMSessionFetcher), Firebase family (FirebaseAuth, FirebaseCore, FirebaseMessaging, FirebaseCrashlytics, FirebaseFirestore), Facebook SDKs (FBSDKCoreKit, FBSDKLoginKit, FBSDKShareKit), Flutter framework itself, popular Flutter plugins (connectivity_plus, device_info_plus, file_picker, flutter_inappwebview, geolocator_apple, image_picker_ios, package_info_plus, path_provider, shared_preferences_ios, url_launcher, webview_flutter_wkwebview), imaging libraries (Kingfisher, SDWebImage), UI frameworks (IQKeyboardManager, MBProgressHUD, SVProgressHUD), data handling (FMDB, RealmSwift, sqflite), reactive programming (RxSwift, RxCocoa), and cross-platform frameworks (Capacitor, Cordova, UnityFramework).

**Your three problematic SDKs—GTMAppAuth, GTMSessionFetcher, and GoogleSignIn—are explicitly on this list** at positions 43, 44, and 39 respectively. Also included are their dependencies: GoogleToolboxForMac (#40), GoogleDataTransport (#38), and GoogleUtilities (#41). The list was published in late December 2023, and Apple clarified that any version of a listed SDK requires a privacy manifest, including older versions. Even SDKs that repackage or embed these listed frameworks must include privacy manifests.

Importantly, even if an SDK is not on this official list, it still needs a privacy manifest if it uses Required Reason APIs, collects data about users, or contacts tracking domains. The list represents commonly used SDKs that Apple proactively identified, but the requirement extends beyond just these 86 frameworks. SDK developers are responsible for creating and distributing privacy manifests, while app developers are responsible for ensuring all code in their apps—including third-party dependencies—complies with Apple's requirements.

## Minimum Google SDK versions with privacy manifest support

Google released privacy manifest support across its iOS SDKs in March 2024, with **GoogleSignIn version 7.1.0** (released March 26, 2024) as the critical minimum. This version added privacy manifest support via pull request #382 and requires GTMSessionFetcher 3.3.0+ and GTMAppAuth 4.1.1+. Google issued an official notice stating: "Starting May 1, 2024, Apple requires Privacy Manifests and signatures for iOS applications that use commonly-used SDKs, including GoogleSignIn-iOS. Upgrade to GoogleSignIn-iOS v7.1.0+ before May 1, 2024."

**GTMAppAuth version 4.1.0** (released March 12, 2024) added privacy manifest support through pull request #239, though version 4.1.1 (March 14, 2024) is strongly recommended as it fixed privacy info bundling issues. The 4.1.0 release also fixed a keychain key bug. GoogleSignIn 7.1.0 specifically requires GTMAppAuth 4.1.1 or later in its dependency specifications.

**GTMSessionFetcher version 3.3.0 or later** includes privacy manifest files, with version 3.3.2 (released March 20, 2024) recommended for full support including visionOS compatibility. The privacy manifest files are located in multiple resource paths: Sources/Core/Resources/PrivacyInfo.xcprivacy, Sources/Full/Resources/PrivacyInfo.xcprivacy, and Sources/LogView/Resources/PrivacyInfo.xcprivacy. CocoaPods support for privacy manifests requires CocoaPods 1.12.0 or later to properly bundle these resources.

The good news: **no breaking API changes** occurred between versions 7.0.0 to 7.1.0 for GoogleSignIn, or 4.0.0 to 4.1.0 for GTMAppAuth, or within the 3.x series for GTMSessionFetcher. These updates primarily add privacy manifest support and are backward compatible with existing implementations. However, if you're upgrading from much older versions (GoogleSignIn pre-7.0.0 or GTMAppAuth pre-3.0.0), be aware that GTMAppAuth 3.0.0 was a complete rewrite from Objective-C to Swift with significant API changes including renaming GTMAppAuthFetcherAuthorization to GTMAuthSession, and CocoaPods users must include `use_frameworks!` in their Podfile.

## Checking current SDK versions in Flutter iOS projects

Your Flutter project has a layered dependency structure where Flutter packages in pubspec.yaml depend on platform-specific implementations that in turn depend on native iOS CocoaPods. To check your current versions, start with **pubspec.yaml** in your project root, which lists your direct Flutter dependencies. The google_sign_in package should show a version number like `google_sign_in: ^6.0.0` or similar—you need to update this to ^7.2.0 or later.

Run `flutter pub deps` to view all your dependencies and their versions in a tree structure, or `flutter pub outdated` to specifically identify packages with available updates. This shows both your direct dependencies and transitive dependencies, helping you understand the full dependency chain.

The **Podfile.lock** file at `ios/Podfile.lock` is the authoritative source for your actual installed iOS SDK versions. Open this file and search for GoogleSignIn, GTMAppAuth, and GTMSessionFetcher. You'll see entries like `- GoogleSignIn (7.1.0)` showing the exact version installed. The PODS section shows installed pod versions, the DEPENDENCIES section shows what your project requires, and EXTERNAL SOURCES shows Flutter plugin paths. This file should be committed to version control as it ensures consistent builds across different environments.

To check for outdated pods directly, navigate to your ios directory and run `pod outdated`. This command queries the CocoaPods specs repository and shows which pods have newer versions available. You can verify the Flutter plugin specifications by examining `.symlinks/plugins/google_sign_in_ios/darwin/google_sign_in_ios.podspec`, which defines the native SDK dependencies that Flutter's google_sign_in package requires. This podspec file should contain a line like `s.dependency 'GoogleSignIn', '~> 7.1'` in updated versions.

## Step-by-step update process for Google dependencies

Begin by updating your **pubspec.yaml** to specify the latest google_sign_in version. Change the dependency line to `google_sign_in: ^7.2.0` (or the latest version available when you're updating). Ensure your Flutter environment is at least version 3.19.0 or later, as earlier versions lack proper privacy manifest support. Run `flutter pub get` to fetch the updated package metadata, followed by `flutter pub upgrade google_sign_in` to actually upgrade the package to the latest compatible version within the constraint you specified.

Next, perform a comprehensive clean of your build artifacts. Run `flutter clean` from your project root to remove Flutter build caches. Navigate to the ios directory with `cd ios` and delete all pod-related files and folders: `rm -rf Pods`, `rm -rf Podfile.lock`, and `rm -rf .symlinks`. This nuclear option ensures no cached dependencies cause version conflicts. Return to the project root with `cd ..`.

Now update your CocoaPods specs repository to ensure you're pulling the latest available pod versions. From the ios directory, run `pod repo update` which refreshes your local copy of the CocoaPods specs repository. You can also use `pod install --repo-update` to combine the repository update with the installation step. The update process can take several minutes as it downloads the latest pod specifications from GitHub.

Install the updated pods by running `pod install` from the ios directory. Use `pod install --verbose` if you want detailed output showing exactly what's being downloaded and installed. CocoaPods reads your project's .podspec files (located in .symlinks for Flutter plugins), resolves dependencies, downloads the frameworks, and generates the Pods directory and Podfile.lock. Watch for the GoogleSignIn, GTMAppAuth, and GTMSessionFetcher lines in the output—they should show versions 7.1+, 4.1.1+, and 3.3.0+ respectively.

**The complete update workflow in order:**

```bash
# 1. Edit pubspec.yaml to update google_sign_in: ^7.2.0
# 2. Get updated Flutter dependencies
flutter pub upgrade google_sign_in

# 3. Clean all build artifacts
flutter clean
cd ios
rm -rf Pods Podfile.lock .symlinks
cd ..

# 4. Reinstall dependencies
flutter pub get
cd ios
pod repo update
pod install --verbose

# 5. Verify versions
cat Podfile.lock | grep -A 3 "GoogleSignIn"

# 6. Return to root and test build
cd ..
flutter build ios --release
```

One critical note: if you encounter CocoaPods version issues, ensure you're running CocoaPods 1.12.0 or later by checking `pod --version`. Update if needed with `sudo gem install cocoapods` (or `sudo arch -x86_64 gem install cocoapods` on Apple Silicon Macs if you encounter architecture issues).

## Verifying privacy manifest files after updating

After updating your dependencies, verification is essential before submitting to TestFlight. The most direct method is using the find command: from your project root, run `find ios/Pods -name "PrivacyInfo.xcprivacy"`. This should return three paths: `ios/Pods/GoogleSignIn/Resources/PrivacyInfo.xcprivacy`, `ios/Pods/GTMSessionFetcher/Resources/PrivacyInfo.xcprivacy`, and `ios/Pods/GTMAppAuth/Resources/PrivacyInfo.xcprivacy`. If any of these are missing, your pod versions are still too old or the installation didn't complete successfully.

You can manually inspect a specific pod's resources directory: `ls -la ios/Pods/GoogleSignIn/Resources/` should list PrivacyInfo.xcprivacy among the framework's bundled resources. Open one of these files in a text editor to verify it's a properly formatted XML plist containing the four required top-level keys: NSPrivacyTracking, NSPrivacyTrackingDomains, NSPrivacyCollectedDataTypes, and NSPrivacyAccessedAPITypes.

**Generate a privacy report in Xcode** for comprehensive verification. Open `ios/Runner.xcworkspace` in Xcode (critical: open the .xcworkspace file, not the .xcodeproj file, as only the workspace includes CocoaPods dependencies). Select Product → Archive and wait for the archive process to complete. Once finished, the Organizer window opens showing your archives. Right-click on the latest archive and select "Generate Privacy Report." Xcode produces a PDF aggregating all privacy manifests from your app and its SDKs.

Important caveat: the privacy report only includes nutrition labels from dynamic libraries and SDK resource bundles. Static libraries' manifests may not appear in the report even if correctly configured, so an empty or incomplete PDF doesn't necessarily indicate an error. The report is most useful for confirming that your dynamic frameworks have properly bundled privacy manifests. If GoogleSignIn appears in the report with its data collection practices documented, you've successfully integrated the privacy manifest.

Run a test build before submitting: `flutter build ios --release --verbose` from your project root. Watch the build output for any privacy-related warnings. The build should complete successfully without errors about missing privacy manifests. When the build succeeds, you can proceed with confidence to the archive and upload process in Xcode.

## Breaking changes and migration considerations

The March 2024 privacy manifest versions of Google SDKs are **largely backward compatible** with their immediate predecessors. GoogleSignIn 7.1.0 maintains API compatibility with 7.0.0, introducing only privacy manifest support and Firebase App Check support without breaking existing implementations. Similarly, GTMAppAuth 4.1.0 and 4.1.1 don't break APIs from 4.0.0, and GTMSessionFetcher 3.3.x versions maintain compatibility within the 3.x series.

However, if you're upgrading from significantly older versions, be aware of major changes. GoogleSignIn 7.0.0 (released earlier) introduced substantial improvements including configuration via Info.plist rather than code, Swift Concurrency support with async/await patterns, and significant API improvements to GIDSignIn and GIDGoogleUser classes. The minimum iOS deployment target increased to iOS 11+. Review Google's migration guide at developers.google.com/identity/sign-in/ios/release if upgrading from version 6.x or earlier.

GTMAppAuth version 3.0.0 represented a **complete rewrite from Objective-C to Swift** with major breaking changes. The primary class GTMAppAuthFetcherAuthorization was renamed to GTMAuthSession, and the architecture shifted to support modern Swift patterns. If you're on GTMAppAuth 2.x or earlier, budget time for refactoring your authentication code. CocoaPods users must add `use_frameworks!` in their Podfile when using version 3.0.0 or later, as the Swift rewrite requires dynamic frameworks rather than static libraries.

Dependency conflicts are the most common migration challenge. Firebase iOS SDK versions older than 10.22.0 may specify incompatible versions of GTMSessionFetcher or GoogleToolboxForMac. If you use Firebase, update to version 10.23.0 or later (released alongside the privacy manifest updates in March-April 2024). MLKit and other Google services also have version constraints—check your Podfile.lock carefully after updating and resolve conflicts by updating all Google dependencies together. Run `flutter pub deps --style=compact` to visualize your dependency tree and identify conflicting version constraints.

Test thoroughly after updating, especially authentication flows. While the APIs remain largely compatible, subtle behavioral changes can occur. Verify Google Sign-In functionality on both simulator and physical devices, test edge cases like signing out and re-authenticating, and ensure your Info.plist configuration remains correct (particularly the GIDClientID and CFBundleURLSchemes entries).

## Alternative solutions when immediate updates aren't possible

If you cannot update to privacy-manifest-compliant SDK versions due to dependency conflicts or organizational constraints, you have several workaround options, though all are temporary and updating remains the recommended long-term solution.

**Creating an app-level privacy manifest** allows you to declare Required Reason API usage for both your app and third-party SDKs that lack manifests. Create a PrivacyInfo.xcprivacy file at your app root (ios/App/App folder for Capacitor, ios/Runner for standard iOS projects) using Xcode's File → New File → App Privacy File template. Set target membership correctly in the file inspector. Include NSPrivacyAccessedAPITypes declarations for all APIs that your dependencies use, referencing Apple's approved reason codes. Document which declarations correspond to which SDKs for future maintenance. This approach satisfies the Required Reason API requirement (avoiding ITMS-91053 errors) but doesn't fully satisfy the third-party SDK manifest requirement for ITMS-91061.

**Manual framework privacy manifest injection** works for specific cases. Locate the SDK's privacy manifest from its GitHub repository (even if not in your installed version). Create a PrivacyInfo.xcprivacy file in Pods/[FrameworkName]/Resources/ in Xcode and add the manifest content. Set Target Membership to all affected SDK targets. However, this approach has a critical flaw: the Pods directory is regenerated on every `pod install`, wiping out your manual changes. You must implement a post_install script in your Podfile to automatically inject the manifest after each pod installation.

**Forcing specific pod versions in your Podfile** can resolve dependency conflicts. Add explicit version constraints like `pod 'GTMSessionFetcher', '~> 3.3.2'` to force CocoaPods to use privacy-manifest-compliant versions even if other dependencies specify looser constraints. Use a post_install block for additional configuration if needed. This approach works when the conflict is merely a version specification issue rather than a true incompatibility.

**Forking and patching unmaintained dependencies** is a last resort when SDK maintainers haven't updated their libraries. Multiple developers successfully resolved ITMS-91061 by forking Flutter packages like flutter_inappwebview, updating the .podspec file to force newer dependency versions with privacy manifests, and using dependency_overrides in pubspec.yaml to point to their forked version. For example, forcing OrderedSet 6.0.3 resolved privacy manifest issues for several flutter_inappwebview users. This approach requires ongoing maintenance and merging upstream changes.

Consider whether you actually need the problematic SDK. If you're using Google Sign-In but it's not core to your app's functionality, temporarily removing it might be faster than resolving dependency conflicts, allowing you to ship your update while you work on a proper integration of the updated SDK versions.

## Validating your fix before TestFlight resubmission

Apple provides no pre-submission validation tool that definitively confirms privacy manifest compliance, but you can significantly reduce rejection risk through systematic checking. Start with **format validation using plutil**: run `plutil -lint ios/Runner/PrivacyInfo.xcprivacy` (and the same for any manually created manifests) to verify the file is a properly formatted property list. This command validates XML structure but doesn't check semantic correctness of keys or values.

**Open the privacy manifest in Xcode 15 or later** as a visual check. If Xcode displays the file in a table format similar to Info.plist with expandable keys and values, the structure is correct. If Xcode shows plain XML or refuses to open the file, it's malformed. Verify all four required top-level keys are present: NSPrivacyTracking, NSPrivacyTrackingDomains, NSPrivacyCollectedDataTypes, and NSPrivacyAccessedAPITypes. Even if you don't use tracking or collect no data, these keys must exist with false/empty values.

**Check target membership meticulously**. In Xcode, select your privacy manifest file in the navigator and open the File Inspector (right sidebar). The Target Membership section must have your app target checked. This is the single most commonly missed step—the file can exist in your project but won't be included in the IPA archive without target membership. Many developers spend hours debugging only to discover this checkbox was unchecked.

Run the find command to verify SDK privacy manifests: `find ios/Pods -name "PrivacyInfo.xcprivacy"` should return paths for GoogleSignIn, GTMSessionFetcher, and GTMAppAuth in their respective Resources directories. If any are missing, your pod versions are still too old. Cross-reference with `cat ios/Podfile.lock | grep -A 3 "GoogleSignIn"` to confirm versions are 7.1.0+, 4.1.1+, and 3.3.0+ respectively.

**Generate and review the privacy report** through Xcode's archive process. Product → Archive, then right-click the archive and select "Generate Privacy Report." While the PDF may not show static framework manifests, it should document any data collection your app performs and show dynamic framework privacy practices. Review it for completeness and accuracy—this is what Apple's reviewers will see.

Perform a complete clean rebuild before archiving: `flutter clean`, delete ios/Pods and ios/Podfile.lock, run `flutter pub get`, then `cd ios && pod install`. Build with `flutter build ios --release --verbose` and watch for any privacy-related warnings in the output. When the build succeeds without warnings, archive in Xcode and upload to App Store Connect. Don't skip the build test—catching issues locally saves 24-48 hours of TestFlight review time.

## Timeline expectations and App Store review process

TestFlight beta review times have **increased significantly in 2024-2025** compared to earlier years. The first build of a new version number typically requires 24-48 hours for beta review, with the average creeping toward the 48-hour mark. Fastest reported times are 50 minutes to 1 hour (rare, typically during US business hours), while slowest reports extend to 5-10 days during peak periods like WWDC or major iOS releases.

Subsequent builds using the same version number usually receive instant approval if marked "no significant changes," available to testers immediately without beta review. However, Apple only triggers beta review validation for new version numbers, which means if you're just updating privacy manifests, you must increment your version number to force re-review of the privacy manifest compliance.

Build processing time alone (before review even begins) ranges from 15 minutes to several hours. Your build goes through stages: "Processing" (30 minutes to 2+ hours), "Waiting for Review," "In Review," and finally "Testing." External beta testing requires review, while internal testing (up to 100 devices) does not. If your build remains stuck in "Waiting for Review" for more than 48 hours, check developer.apple.com/system-status/ for Apple infrastructure issues.

Full App Store review for public release averages around 24 hours as of late 2024, with some developers reporting approvals in under an hour. Privacy manifest issues currently don't prevent approval for existing apps but trigger warning emails—though this leniency is decreasing as enforcement tightens. Interestingly, many developers report TestFlight review taking **longer than App Store review** in 2024-2025, a reversal from earlier years when TestFlight was meant for rapid iteration.

Several factors affect review timing: submissions during US business hours (Pacific Time) tend to be faster; proximity to major Apple events like WWDC or iOS launches significantly slows reviews; weekend and holiday submissions face substantial delays; and privacy manifest compliance issues may extend review time as reviewers manually verify SDK compliance. One developer frustration is common: "We've been waiting over 24 hours once again for our beta review. Apple is making it impossible for us to effectively use their TestFlight service for our normal release pipeline."

Plan your submission timing accordingly. If you need beta testers to validate your fix before the weekend, submit by Wednesday morning Pacific Time to account for potential 48-hour review. Avoid submitting immediately before major Apple events or iOS version releases. When resubmitting after an ITMS-91061 rejection, be patient—even with the fix in place, Apple's review queue processes sequentially.

## Common pitfalls and troubleshooting ITMS-91061 errors

The most insidious pitfall is **dependency version conflicts** where updating one SDK breaks others. Developers frequently encounter situations where updating GTMSessionFetcher to 4.3.0 for privacy manifest compliance causes Firebase or MLKit to fail compilation due to version constraints. This creates a cascade of dependency conflicts that can make your app uncompilable. The solution requires updating all Google dependencies together: Firebase to 10.25.0+, GoogleSignIn to 7.1.0+, and any MLKit or other Google services to their 2024 versions. Test with `flutter pub get` or `pod install` before committing to the full rebuild.

**Static vs. dynamic framework manifest detection** causes significant confusion. Xcode's privacy report generator cannot find manifests in static libraries, only dynamic frameworks. Many developers panic when their privacy report appears empty despite properly installed privacy manifests. This is a known limitation—Apple has stated that "in the future, these required reason requirements will expand to include the entire app binary," implying current detection has gaps. Your workaround options are using dynamic frameworks when possible, including manifests in associated resource bundles, or declaring SDK API usage at the app level.

The "Multiple commands produce PrivacyInfo.xcprivacy" build error occurs when SDK developers use `s.resources = 'PrivacyInfo.xcprivacy'` instead of `s.resource_bundles` in their podspec. This causes CocoaPods to copy the file multiple times, creating duplicate file errors during build. If you encounter this as an SDK consumer, report it to the maintainer—the fix requires them to update their podspec. If you're an SDK developer, always use resource_bundles: `s.resource_bundles = {'SDKName_Privacy' => ['Resources/PrivacyInfo.xcprivacy']}`.

**Receiving ITMS-91061 errors after updating packages** is surprisingly common and frustrating. Multiple developers report getting rejection emails even after updating to versions that supposedly include privacy manifests. Reasons include: Apple's detection system lagging behind actual manifest presence (their processing takes time to recognize new versions), static linking preventing manifest detection, CocoaPods integration issues with Xcode 15, manifests existing but missing required keys, or stale caches. The nuclear option solution: `flutter clean`, delete all pod-related files, update CocoaPods itself to 1.12.0+, reinstall everything fresh, and verify manifests are present before rebuilding.

Missing target membership remains the single most common configuration error. Even when the PrivacyInfo.xcprivacy file exists in your project, it won't be included in the IPA archive unless you check the target membership box in Xcode's File Inspector. This simple checkbox causes hours of debugging for developers who don't realize the file is technically present but not bundled. Always verify target membership as your first troubleshooting step.

The "Privacy Report shows nothing" misconception leads developers to believe something is wrong when they generate an empty PDF. The privacy report only shows collected data types and tracking domains—it doesn't necessarily display Required Reason API declarations. An empty report is completely normal for apps that don't collect user data or perform tracking. Don't waste time debugging a non-issue; focus on whether the actual privacy manifest files exist in your framework bundles.

## Conclusion: the path to TestFlight approval

Your resolution path is straightforward: update google_sign_in to version 7.2.0 in pubspec.yaml, clean your build environment completely, reinstall CocoaPods dependencies to pull GoogleSignIn 7.1.0+, GTMAppAuth 4.1.1+, and GTMSessionFetcher 3.3.0+, verify the privacy manifests exist using the find command, generate a privacy report in Xcode to confirm compliance, and rebuild your app for release. The entire process takes 30-60 minutes assuming no dependency conflicts. Submit your updated build and expect 24-48 hours for TestFlight beta review—plan accordingly if you need testers before a specific deadline.

The broader context matters for your long-term development strategy. Apple's privacy manifest enforcement represents a fundamental shift in iOS development practices, moving from post-release privacy label documentation to pre-submission technical verification. The February 12, 2025 enforcement date establishes hard rejections rather than warnings, and Apple continuously expands the list of required SDKs. Stay current with SDK updates, monitor your dependencies proactively, and budget time in your release cycles for privacy manifest compliance. The days of rapidly integrating third-party SDKs without considering their privacy implications are over.

Most importantly, understand that ITMS-91061 is not a reflection of your app's quality or development practices—it's purely a dependency version issue. Google released the required fixes in March 2024, and countless developers have successfully resolved identical errors by following the update process. Your specific error for GTMAppAuth, GTMSessionFetcher, and GoogleSignIn has a documented solution with known working versions. Update confidently, verify thoroughly, and resubmit. Your next TestFlight build will almost certainly succeed.