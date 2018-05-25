using Fuse;
using Fuse.Platform;
using Uno;
using Uno.Compiler.ExportTargetInterop;
using Firebase.Authentication;


namespace Firebase.Authentication.Facebook.JS
{

[extern(Android) ForeignInclude(Language.Java,
					"com.fuse.Activity",
					"android.content.Intent",
                    "com.facebook.*",
                    "com.facebook.login.*",
                    "com.facebook.appevents.AppEventsLogger",
                    "com.google.android.gms.tasks.OnCompleteListener",
                    "com.google.android.gms.tasks.Task",
                    "com.google.firebase.auth.*")]

    [extern(iOS) Require("Cocoapods.Podfile.Target", "pod 'FBSDKCoreKit'")]
    [extern(iOS) Require("Cocoapods.Podfile.Target", "pod 'FBSDKShareKit'")]
    [extern(iOS) Require("Cocoapods.Podfile.Target", "pod 'FBSDKLoginKit'")]
    [extern(iOS) Require("AppDelegate.SourceFile.Declaration", "#include <FBSDKCoreKit/FBSDKCoreKit.h>")]
    [extern(iOS) Require("Source.Include", "Firebase/Firebase.h")]
    [extern(iOS) Require("Source.Include", "Firebase/Firebase.h")]
    [extern(iOS) Require("Source.Include", "FirebaseAuth/FirebaseAuth.h")]
    [extern(iOS) Require("Source.Include", "FBSDKCoreKit/FBSDKCoreKit.h")]
    [extern(iOS) Require("Source.Include", "FBSDKLoginKit/FBSDKLoginKit.h")]
    [extern(iOS) Require("Source.Include", "@{Firebase.Authentication.Facebook.JS.FacebookModule:Include}")]
    [extern(iOS) Require("Source.Include", "@{FacebookService:Include}")]

	public class FacebookAuthentication
    {

    	public FacebookAuthentication()
		{

		}

		[Foreign(Language.ObjC)]
		public extern(iOS) void Login()
		@{
			FBSDKLoginManager* login = [[FBSDKLoginManager alloc] init];
			[login
				logInWithReadPermissions: @[@"public_profile"]
				fromViewController: [[[UIApplication sharedApplication] keyWindow] rootViewController]
				handler: ^(FBSDKLoginManagerLoginResult* result, NSError* error)
				{
					if (error)
					{	
						NSString * message = @"Facebook SignIn Failed. Error code: ";
        				NSString *errorMessage = [NSString stringWithFormat:@"%@ %ld", message, error.code];
						@{OnFailure(string):Call(errorMessage)};
                        @{Firebase.Authentication.Facebook.JS.FacebookModule.OnFailed(string):Call(errorMessage)};
						return;
					}
					if (result.isCancelled)
					{
						NSString *error = @"Facebook Auth Stage Cancelled";
						@{OnFailure(string):Call(error)};
                        @{Firebase.Authentication.Facebook.JS.FacebookModule.OnFailed(string):Call(error)};
						return;
					}
					@{OnAuth(ObjC.Object):Call(result)};
				}
			];
		@}

		extern(Android) Java.Object _callbackManager;
	    [Foreign(Language.Java)]
		public extern(Android) void Login()
		@{
	        FacebookSdk.sdkInitialize(Activity.getRootActivity());
	        final CallbackManager callbackManager = CallbackManager.Factory.create();
	        @{FacebookAuthentication:Of(_this)._callbackManager:Set(callbackManager)};
	        Activity.subscribeToResults(new Activity.ResultListener() {
	            @Override
	        	    public boolean onResult(int requestCode, int resultCode, Intent data) {
	                    return callbackManager.onActivityResult(requestCode, resultCode, data);
	                }
	        });
			CallbackManager callbackManagerFrom = (CallbackManager)@{FacebookAuthentication:Of(_this)._callbackManager:Get()};
			LoginManager.getInstance().registerCallback(callbackManagerFrom,
				new FacebookCallback<LoginResult>()
				{
					public void onSuccess(LoginResult loginResult) {
                        @{OnAuth(Java.Object):Call(loginResult.getAccessToken())};
                    }

                    public void onCancel() {
                        @{OnFailure(string):Call("Facebook Auth Stage Cancelled")};
                        @{Firebase.Authentication.Facebook.JS.FacebookModule.OnFailed(string):Call("Facebook Auth Stage Cancelled")};
                    }

                    public void onError(FacebookException error) {
                        String reason = "Facebook Auth Stage Errored (" + error.getClass().getName() + "):\n" + error.getMessage();
                        @{OnFailure(string):Call(reason)};
                        @{Firebase.Authentication.Facebook.JS.FacebookModule.OnFailed(string):Call(reason)};
                    }
				}
			);
			LoginManager.getInstance().logInWithReadPermissions(Activity.getRootActivity(), java.util.Arrays.asList("public_profile"));
		@}

		extern(Mobile)
		static void OnSuccess(string message)
        {
            AuthService.AnnounceSignIn(AuthProviderName.Facebook);
        }

        extern(Mobile)
        static void OnFailure(string reason)
        {
            AuthService.SignalError(-1, reason);
     	}
     	
		[Foreign(Language.Java)]
        static extern(Android) void OnAuth(Java.Object result)
        @{
            final AccessToken token = (AccessToken)result;
            AuthCredential credential = FacebookAuthProvider.getCredential(token.getToken());
            FirebaseAuth.getInstance().signInWithCredential(credential)
                .addOnCompleteListener(com.fuse.Activity.getRootActivity(), new OnCompleteListener<AuthResult>() {
                        public void onComplete(Task<AuthResult> task) {
                            if (task.isSuccessful()) {
                                @{Firebase.Authentication.Facebook.JS.FacebookModule.Auth(string):Call(token.getToken())};
                                @{OnSuccess(string):Call("Success")};
                            }
                            else
                                @{OnFailure(string):Call("Authentication against Firebase failed")};
                        }});
        @}

        [Foreign(Language.ObjC)]
        static extern(iOS) void OnAuth(ObjC.Object result)
        @{
        	FBSDKLoginManagerLoginResult *accessToken = (FBSDKLoginManagerLoginResult *)result;
            NSString *tokenStr = accessToken.token.tokenString;

        	if (tokenStr==NULL)
            {
                @{OnFailure(string):Call(@"Authentication against Firebase failed")};
                return;
            }
        
            FIRAuthCredential* credential = [FIRFacebookAuthProvider credentialWithAccessToken:tokenStr];

                // auth againsts firebase
            [[FIRAuth auth] signInWithCredential:credential
                completion:^(FIRUser* fuser, NSError* ferror) {
                    if (ferror)
                        @{OnFailure(string):Call(@"Authentication against Firebase failed")};
                    else {
                         @{Firebase.Authentication.Facebook.JS.FacebookModule.Auth(string):Call(tokenStr)};
                         @{OnSuccess(string):Call(@"success")};
                     }
                }];
        @}


        [Foreign(Language.ObjC)]
        public extern(iOS) void LinkFacebook()
        @{
            FBSDKLoginManager* login = [[FBSDKLoginManager alloc] init];
            [login
                logInWithReadPermissions: @[@"public_profile"]
                fromViewController: [[[UIApplication sharedApplication] keyWindow] rootViewController]
                handler: ^(FBSDKLoginManagerLoginResult* result, NSError* error)
                {
                    if (error)
                    {
                        NSString * message = @"Facebook SignIn Failed. Error code: ";
                        NSString *errorMessage = [NSString stringWithFormat:@"%@ %ld", message, error.code];
                        @{OnFailure(string):Call(errorMessage)};
                        @{Firebase.Authentication.Facebook.JS.FacebookModule.OnFailed(string):Call(errorMessage)};
                        return;
                    }
                    if (result.isCancelled)
                    {
                        NSString *error = @"Facebook Auth Stage Cancelled";
                        @{OnFailure(string):Call(error)};
                        @{Firebase.Authentication.Facebook.JS.FacebookModule.OnFailed(string):Call(error)};
                        return;
                    }
                    @{OnLinkFacebookWithFirebase(ObjC.Object):Call(result)};
                }
            ];
        @}

        [Foreign(Language.Java)]
        public extern(Android) void LinkFacebook()
        @{
            FacebookSdk.sdkInitialize(Activity.getRootActivity());
            final CallbackManager callbackManager = CallbackManager.Factory.create();
            @{FacebookAuthentication:Of(_this)._callbackManager:Set(callbackManager)};
            Activity.subscribeToResults(new Activity.ResultListener() {
                @Override
                    public boolean onResult(int requestCode, int resultCode, Intent data) {
                        return callbackManager.onActivityResult(requestCode, resultCode, data);
                    }
            });
            CallbackManager callbackManagerFrom = (CallbackManager)@{FacebookAuthentication:Of(_this)._callbackManager:Get()};
            LoginManager.getInstance().registerCallback(callbackManagerFrom,
                new FacebookCallback<LoginResult>()
                {
                    public void onSuccess(LoginResult loginResult) {
                        @{OnLinkFacebookWithFirebase(Java.Object):Call(loginResult.getAccessToken())};
                    }

                    public void onCancel() {
                        @{OnFailure(string):Call("Facebook Auth Stage Cancelled")};
                        @{Firebase.Authentication.Facebook.JS.FacebookModule.OnFailed(string):Call("Facebook Auth Stage Cancelled")};
                    }

                    public void onError(FacebookException error) {
                        String reason = "Facebook Auth Stage Errored (" + error.getClass().getName() + "):\n" + error.getMessage();
                        @{OnFailure(string):Call(reason)};
                        @{Firebase.Authentication.Facebook.JS.FacebookModule.OnFailed(string):Call(reason)};
                    }
                }
            );
            LoginManager.getInstance().logInWithReadPermissions(Activity.getRootActivity(), java.util.Arrays.asList("public_profile"));
        @}


        [Foreign(Language.ObjC)]
        static extern(iOS) void OnLinkFacebookWithFirebase(ObjC.Object result)
        @{
            FBSDKLoginManagerLoginResult *accessToken = (FBSDKLoginManagerLoginResult *)result;
            NSString *tokenStr = accessToken.token.tokenString;

            if (tokenStr==NULL)
            {
                @{OnFailure(string):Call(@"Authentication against Firebase failed")};
                return;
            }

            FIRAuthCredential *credential = [FIRFacebookAuthProvider credentialWithAccessToken:tokenStr];

            [[FIRAuth auth].currentUser linkAndRetrieveDataWithCredential:credential
            completion:^(FIRAuthDataResult *result, NSError *_Nullable error) {
                if (error) {
                    if (error.code == FIRAuthErrorCodeProviderAlreadyLinked) {
                        @{Firebase.Authentication.Facebook.JS.FacebookModule.Auth(string):Call(tokenStr)};
                        @{OnSuccess(string):Call(@"success")};
                    } else {
                        @{OnFailure(string):Call(@"Link Firebase failed")};
                        @{Firebase.Authentication.Facebook.JS.FacebookModule.OnFailed(string):Call(error.localizedDescription)};
                    }
                } else {
                    @{Firebase.Authentication.Facebook.JS.FacebookModule.Auth(string):Call(tokenStr)};
                    @{OnSuccess(string):Call(@"success")};
                }
            }];
        @}

        [Foreign(Language.Java)]
        static extern(Android) void OnLinkFacebookWithFirebase(Java.Object result)
        @{
            final AccessToken token = (AccessToken)result;
            AuthCredential credential = FacebookAuthProvider.getCredential(token.getToken());
            FirebaseAuth.getInstance().getCurrentUser().linkWithCredential(credential)
                    .addOnCompleteListener(com.fuse.Activity.getRootActivity(), new OnCompleteListener<AuthResult>() {
                        @Override
                        public void onComplete(Task<AuthResult> task) {
                            if (task.isSuccessful()) {
                                @{Firebase.Authentication.Facebook.JS.FacebookModule.Auth(string):Call(token.getToken())};
                                @{OnSuccess(string):Call("Success")};
                            } else {
                                if (task.getException() != null) {
                                    if (task.getException().getMessage().equals("User has already been linked to the given provider.")) {
                                        @{Firebase.Authentication.Facebook.JS.FacebookModule.Auth(string):Call(token.getToken())};
                                        @{OnSuccess(string):Call("Success")};
                                    } else {
                                        @{OnFailure(string):Call("Authentication against Firebase failed")};
                                        @{Firebase.Authentication.Facebook.JS.FacebookModule.OnFailed(string):Call(task.getException().getMessage())};
                                    }
                                } else {
                                    @{OnFailure(string):Call("Authentication against Firebase failed")};
                                    @{Firebase.Authentication.Facebook.JS.FacebookModule.OnFailed(string):Call("Link Firebase failed")};
                                }
                            }
                        }
                    });
        @}
    }
}