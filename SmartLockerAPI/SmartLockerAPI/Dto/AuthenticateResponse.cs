using SmartLocker.Models;

namespace SmartLockerAPI.Dto
{
    public class AuthenticateResponse
    {
        public string Id { get; set; }
        public string name { get; set; }
        public string mail { get; set; }
        public string phone { get; set; }
        public string role { get; set; }
        public string Token { get; set; }


        public AuthenticateResponse(User user, string token)
        {
            Id = user.UserId;
            name = user.Name;
            mail = user.Mail;
            phone = user.Phone;
            role = user.RoleId;
            Token = token;
        }
    }
}