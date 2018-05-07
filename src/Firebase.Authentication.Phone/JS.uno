using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Text;
using Uno.Platform;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;
using Fuse;
using Fuse.Scripting;
using Fuse.Reactive;

namespace Firebase.Authentication.Phone.JS
{
    /**
    */
    [UXGlobalModule]
    public sealed class PhoneModule : NativeModule
    {
        static readonly PhoneModule _instance;
        static NativeEvent _onCodeSent;

        public PhoneModule()
        {
            if(_instance != null) return;
            Uno.UX.Resource.SetGlobalKey(_instance = this, "Firebase/Authentication/Phone");

            Firebase.Authentication.Phone.PhoneService.Init();
            _onCodeSent = new NativeEvent("onCodeSentEvent");
            AddMember(_onCodeSent);

            AddMember(new NativePromise<string, string>("createUserWithPhoneNumber", CreateUserWithPhoneNumber));
            AddMember(new NativePromise<string, string>("validateUserWithCode", ValidateUserWithCode));
        }

        Future<string> CreateUserWithPhoneNumber(object[] args)
        {
            var phone = (string)args[0];
            return new Firebase.Authentication.Phone.CreateUser(phone);
        }

        Future<string> ValidateUserWithCode(object[] args)
        {
            var code = (string)args[0];
            return new Firebase.Authentication.Phone.ValidateUser(code);
        }

        static void CodeSent(string token)
        {
            _onCodeSent.RaiseAsync(_onCodeSent.ThreadWorker, token);
        }

    }
}
