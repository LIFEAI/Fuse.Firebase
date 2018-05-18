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
    public class PhoneService : Firebase.Authentication.AuthProvider
    {
        static bool _initd = false;

        internal static void Init()
        {
            if (_initd) return;
            var es = new PhoneService();
            Firebase.Authentication.AuthService.RegisterAuthProvider(es);
            _initd = true;
        }

        public override AuthProviderName Name { get { return AuthProviderName.Phone; } }

        public override void Start() {}

        public override void SignOut() {}

        public override Promise<string> ReAuthenticate(string phone, string password)
        {
            return new ReAuthenticate(phone);
        }
    }

    extern(!mobile)
    internal class CreateUser : Promise<string>
    {
        public CreateUser(string phone) { }
        public void Reject(string reason) { }
    }

    extern(!mobile)
    internal class ValidateUser : Promise<string>
    {
        public ValidateUser(string code) { }
        public void Reject(string reason) { }
    }

    extern(!mobile)
    internal class ReAuthenticate : Promise<string>
    {
        public ReAuthenticate(string phone ) { }
        public void Reject(string reason) { }
    }

}
