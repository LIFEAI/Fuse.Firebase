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
    [Require("AppDelegate.SourceFile.Declaration", "#include <FirebaseCore/FirebaseCore.h>")]
    [Require("AppDelegate.SourceFile.Declaration", "#include <FirebaseAuth/FirebaseAuth.h>")]
    [Require("Source.Include", "Firebase/Firebase.h")]
    [Require("Source.Include", "FirebaseAuth/FirebaseAuth.h")]
    [Require("Cocoapods.Podfile.Target", "pod 'Firebase/Auth'")]
    extern(iOS)
    class CreateUser : Promise<string>
    {
        [Foreign(Language.ObjC)]
        public CreateUser(string phone)
        @{
            [[FIRPhoneAuthProvider provider] 
            verifyPhoneNumber:phone
            UIDelegate:nil
            completion:^(NSString * _Nullable verificationID, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                    @{CreateUser:Of(_this).Reject(string):Call(error.localizedDescription)};
                }
                else {
                // Sign in using the verificationID and the code sent to the user
                // ...
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:verificationID forKey:@"authVerificationID"];
                    NSLog(@"%@", verificationID);
                    @{CreateUser:Of(_this).Resolve(string):Call(@"Code sent")};
                }
            }];
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
    }

    [Require("Source.Include", "Firebase/Firebase.h")]
    [Require("Source.Include", "FirebaseAuth/FirebaseAuth.h")]
    [Require("Cocoapods.Podfile.Target", "pod 'Firebase/Auth'")]
    extern(iOS)
    class ValidateUser : Promise<string>
    {
        [Foreign(Language.ObjC)]
        public ValidateUser(string code)
        @{
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *verificationID = [defaults stringForKey:@"authVerificationID"];
            NSLog(@"%@", verificationID);
            FIRAuthCredential *credential = [[FIRPhoneAuthProvider provider]
                                             credentialWithVerificationID:verificationID
                                             verificationCode:code];
            [[FIRAuth auth] 
            signInWithCredential:credential
              completion:^(FIRUser *user, NSError *error) {
                  if (error) {
                      NSLog(@"%@", error.localizedDescription);
                        @{ValidateUser:Of(_this).Reject(string):Call(error.localizedDescription)};
                  }
                  else {
                    [user getIDTokenWithCompletion:^(NSString *idToken, NSError* fidError) {
                                if (fidError) {
                                    @{ValidateUser:Of(_this).Reject(string):Call(fidError.localizedDescription)};
                                }
                                else {
                                    @{ValidateUser:Of(_this).Resolve(string):Call(idToken)};
                                }
                            }];
                    }
              }];
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

    [Require("Source.Include", "Firebase/Firebase.h")]
    [Require("Source.Include", "FirebaseAuth/FirebaseAuth.h")]
    [Require("Cocoapods.Podfile.Target", "pod 'Firebase/Auth'")]
    [Require("Source.Include", "@{Firebase.Authentication.User:Include}")]
    extern(iOS)
    class ReAuthenticate : Promise<string>
    {
        [Foreign(Language.ObjC)]
        public ReAuthenticate(string code)
        @{

        @}

        void Reject(string reason)
        {
            Reject(new Exception(reason));
        }

    }

}
