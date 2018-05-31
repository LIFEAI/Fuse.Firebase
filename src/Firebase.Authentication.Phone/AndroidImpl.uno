using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse;
using Fuse.Triggers;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Controls.Native.Android;
using Uno.Threading;
using Firebase.Authentication;

namespace Firebase.Authentication.Phone
{
    [ForeignInclude(Language.Java, "java.util.ArrayList", "java.util.List", "android.content.Intent",
                    "java.util.concurrent.TimeUnit",
                    "android.content.SharedPreferences",
                    "android.util.Log",
                    "android.preference.PreferenceManager",
                    "com.google.android.gms.tasks.OnCompleteListener",
                    "com.google.android.gms.tasks.Task",
                    "com.google.firebase.auth.PhoneAuthProvider",
                    "com.google.firebase.auth.PhoneAuthCredential",
                    "com.google.firebase.auth.FirebaseAuth",
                    "com.google.firebase.auth.AuthResult",
                    "com.google.firebase.FirebaseException",
                    "com.google.firebase.FirebaseTooManyRequestsException",
                    "com.google.firebase.auth.FirebaseAuthInvalidCredentialsException")]
    [Require("Gradle.Dependency.Compile", "com.google.firebase:firebase-auth:11.8.0")]
    extern(android)
    internal class CreateUser : Promise<string>
    {

        extern(android) static internal Java.Object mResendToken;

        public CreateUser(string phone)
        {
            Init(phone);
        }

        [Foreign(Language.Java)]
        public void Init(string phone)
        @{
            PhoneAuthProvider.OnVerificationStateChangedCallbacks mCallbacks = new PhoneAuthProvider.OnVerificationStateChangedCallbacks() {

            @Override
            public void onVerificationCompleted(PhoneAuthCredential credential) {
                // This callback will be invoked in two situations:
                // 1 - Instant verification. In some cases the phone number can be instantly
                //     verified without needing to send or enter a verification code.
                // 2 - Auto-retrieval. On some devices Google Play services can automatically
                //     detect the incoming verification SMS and perform verification without
                //     user action.
                Log.d("Log ", "onVerificationCompleted:" + credential);
                FirebaseAuth.getInstance().signInWithCredential(credential)
                .addOnCompleteListener(com.fuse.Activity.getRootActivity(), new OnCompleteListener<AuthResult>() {
                    public void onComplete(Task<AuthResult> task) {
                        if (task.isSuccessful()) {
                            @{CreateUser:Of(_this).Auth(string):Call(task.getResult().getUser().getIdToken(false).getResult().getToken())};
                        }
                        else {
                            Log.d("Log ", " " + task.getException().toString());
                            @{CreateUser:Of(_this).Reject(string):Call(task.getException().toString())};
                        }
                    }});
            }

            @Override
            public void onVerificationFailed(FirebaseException e) {
                // This callback is invoked in an invalid request for verification is made,
                // for instance if the the phone number format is not valid.
                Log.w("Log ", "onVerificationFailed", e);

                if (e instanceof FirebaseAuthInvalidCredentialsException) {
                    // Invalid request
                    // ...
                } else if (e instanceof FirebaseTooManyRequestsException) {
                    // The SMS quota for the project has been exceeded
                    // ...
                }

                @{CreateUser:Of(_this).Reject(string):Call("SMS failed")};

                // Show a message and update the UI
                // ...
            }

            @Override
            public void onCodeSent(String verificationId,
                                   PhoneAuthProvider.ForceResendingToken token) {
                // The SMS verification code has been sent to the provided phone number, we
                // now need to ask the user to enter the code and then construct a credential
                // by combining the code with a verification ID.
                Log.d("Log ", "onCodeSent:" + verificationId);

                SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(com.fuse.Activity.getRootActivity());
                SharedPreferences.Editor editor = preferences.edit();
                editor.putString("authVerificationID", verificationId);
                editor.apply();
                @{mResendToken:Set(token)};
                @{Firebase.Authentication.Phone.JS.PhoneModule.CodeSent(string):Call("Code sent")};
            }
        };

        PhoneAuthProvider.getInstance().verifyPhoneNumber(
                phone,        // Phone number to verify
                60,                 // Timeout duration
                TimeUnit.SECONDS,   // Unit of timeout
                com.fuse.Activity.getRootActivity(),               // Activity (for callback binding)
                mCallbacks);

        @}

        void Resolve(string message)
        {
            base.Resolve(message);
        }

        void Reject(string reason)
        {
            AuthService.SignalError(-1, reason);
            Reject(new Exception(reason));
        }

        void Auth(string message) {
            AuthService.AnnounceSignIn(AuthProviderName.Phone);
            base.Resolve(message);
        }

    }

    [ForeignInclude(Language.Java, "android.content.SharedPreferences",
                    "android.preference.PreferenceManager",
                    "com.google.android.gms.tasks.OnCompleteListener",
                    "com.google.android.gms.tasks.Task",
                    "com.google.firebase.auth.PhoneAuthProvider",
                    "com.google.firebase.auth.PhoneAuthCredential",
                    "com.google.firebase.auth.FirebaseAuth",
                    "com.google.firebase.auth.AuthResult")]
    [Require("Gradle.Dependency.Compile", "com.google.firebase:firebase-auth:11.8.0")]
    extern(android)
    internal class ValidateUser : Promise<string>
    {

        public ValidateUser(string code)
        {
            Init(code);
        }

        [Foreign(Language.Java)]
        public void Init(string code)
        @{
            SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(com.fuse.Activity.getRootActivity());
            String mVerificationId = preferences.getString("authVerificationID", "Error");
             if (mVerificationId.equals("Error")) {
                @{ValidateUser:Of(_this).Reject(string):Call("Firebase failed to create user")};
                return;
            }
            PhoneAuthCredential credential = PhoneAuthProvider.getCredential(mVerificationId, code);
            FirebaseAuth.getInstance().signInWithCredential(credential)
                .addOnCompleteListener(com.fuse.Activity.getRootActivity(), new OnCompleteListener<AuthResult>() {
                    public void onComplete(Task<AuthResult> task)
                    {
                        if (task.isSuccessful())
                            @{ValidateUser:Of(_this).Resolve(string):Call(task.getResult().getUser().getIdToken(false).getResult().getToken())};
                        else
                            @{ValidateUser:Of(_this).Reject(string):Call(task.getException().getLocalizedMessage())};
                    }
                });
        @}

        void Resolve(string message)
        {
            AuthService.AnnounceSignIn(AuthProviderName.Phone);
            base.Resolve(message);
        }

        void Reject(string reason)
        {
            AuthService.SignalError(-1, reason);
            Reject(new Exception(reason));
        }

    }

    [ForeignInclude(Language.Java, "java.util.ArrayList", "java.util.List", "android.content.Intent",
                        "java.util.concurrent.TimeUnit",
                        "android.content.SharedPreferences",
                        "android.util.Log",
                        "android.preference.PreferenceManager",
                        "com.google.android.gms.tasks.OnCompleteListener",
                        "com.google.android.gms.tasks.Task",
                        "com.google.firebase.auth.PhoneAuthProvider",
                        "com.google.firebase.auth.PhoneAuthCredential",
                        "com.google.firebase.auth.FirebaseAuth",
                        "com.google.firebase.auth.AuthResult",
                        "com.google.firebase.FirebaseException",
                        "com.google.firebase.FirebaseTooManyRequestsException",
                        "com.google.firebase.auth.FirebaseAuthInvalidCredentialsException")]
    [Require("Gradle.Dependency.Compile", "com.google.firebase:firebase-auth:11.8.0")]
    extern(android)
    internal class ResendCodeValidation : Promise<string>
    {

        public ResendCodeValidation(string phone)
        {
            Init(phone);
        }

        [Foreign(Language.Java)]
        public void Init(string phone)
        @{
            PhoneAuthProvider.OnVerificationStateChangedCallbacks mCallbacks = new PhoneAuthProvider.OnVerificationStateChangedCallbacks() {

            @Override
            public void onVerificationCompleted(PhoneAuthCredential credential) {
                // This callback will be invoked in two situations:
                // 1 - Instant verification. In some cases the phone number can be instantly
                //     verified without needing to send or enter a verification code.
                // 2 - Auto-retrieval. On some devices Google Play services can automatically
                //     detect the incoming verification SMS and perform verification without
                //     user action.
                Log.d("Log ", "onVerificationCompleted:" + credential);
                FirebaseAuth.getInstance().signInWithCredential(credential)
                .addOnCompleteListener(com.fuse.Activity.getRootActivity(), new OnCompleteListener<AuthResult>() {
                    public void onComplete(Task<AuthResult> task) {
                        if (task.isSuccessful()) {
                            @{ResendCodeValidation:Of(_this).Auth(string):Call(task.getResult().getUser().getIdToken(false).getResult().getToken())};
                        }
                        else {
                            Log.d("Log ", " " + task.getException().toString());
                            @{ResendCodeValidation:Of(_this).Reject(string):Call(task.getException().toString())};
                        }
                    }});
            }

            @Override
            public void onVerificationFailed(FirebaseException e) {
                // This callback is invoked in an invalid request for verification is made,
                // for instance if the the phone number format is not valid.
                Log.w("Log ", "onVerificationFailed", e);

                if (e instanceof FirebaseAuthInvalidCredentialsException) {
                    // Invalid request
                    // ...
                } else if (e instanceof FirebaseTooManyRequestsException) {
                    // The SMS quota for the project has been exceeded
                    // ...
                }

                @{ResendCodeValidation:Of(_this).Reject(string):Call("SMS failed")};

                // Show a message and update the UI
                // ...
            }

            @Override
            public void onCodeSent(String verificationId,
                                   PhoneAuthProvider.ForceResendingToken token) {
                // The SMS verification code has been sent to the provided phone number, we
                // now need to ask the user to enter the code and then construct a credential
                // by combining the code with a verification ID.
                Log.d("Log ", "onCodeSent:" + verificationId);

                SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(com.fuse.Activity.getRootActivity());
                SharedPreferences.Editor editor = preferences.edit();
                editor.putString("authVerificationID", verificationId);
                editor.apply();
                @{Firebase.Authentication.Phone.JS.PhoneModule.CodeSent(string):Call("Code sent")};
            }
        };

        PhoneAuthProvider.ForceResendingToken mResendToken = (PhoneAuthProvider.ForceResendingToken)@{Firebase.Authentication.Phone.CreateUser.mResendToken};
        PhoneAuthProvider.getInstance().verifyPhoneNumber(
                phone,        // Phone number to verify
                60,                 // Timeout duration
                TimeUnit.SECONDS,   // Unit of timeout
                com.fuse.Activity.getRootActivity(),               // Activity (for callback binding)
                mCallbacks,
                mResendToken);
        @}

        void Resolve(string message)
        {
            base.Resolve(message);
        }

        void Reject(string reason)
        {
            AuthService.SignalError(-1, reason);
            Reject(new Exception(reason));
        }

        void Auth(string message) {
            AuthService.AnnounceSignIn(AuthProviderName.Phone);
            base.Resolve(message);
        }

    }

    extern(android)
    internal class ReAuthenticate : Promise<string>
    {

        [Foreign(Language.Java)]
        public ReAuthenticate(string phone)
        @{

        @}

        void Reject(string reason)
        {
            Reject(new Exception(reason));
        }

    }
}
