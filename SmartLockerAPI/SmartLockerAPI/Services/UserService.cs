using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using SmartLocker.Data;
using SmartLocker.Models;
using SmartLockerAPI.Dto;
using SmartLockerAPI.Helpers;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace SmartLockerAPI.Services
{
    public interface IUserService
    {
        AuthenticateResponse Authenticate(AuthenticateRequest model);
        IEnumerable<User> GetAll();
        User GetById(String id);
    }
    public class UserService : IUserService
    {
        private readonly SmartLockerContext context;
        private List<User> users;
        private readonly AppSettings _appSettings;
        public UserService(SmartLockerContext context, IOptions<AppSettings> appSettings) { 
            this.context = context; 
            users = new List<User>(); 
            users = context.Users.ToList();
            _appSettings = appSettings.Value;

        }
        public AuthenticateResponse Authenticate(AuthenticateRequest model)
        {
            var user = users.SingleOrDefault(x => x.Phone == model.Phone && x.Password == model.Password);

            // return null if user not found
            if (user == null) return null;

            // authentication successful so generate jwt token
            var token = generateJwtToken(user);

            return new AuthenticateResponse(user, token);
        }

        public IEnumerable<User> GetAll()
        {
            return users;
        }

        public User GetById(String id)
        {
            if (string.IsNullOrEmpty(id))
            {
                // Xử lý trường hợp `id` không hợp lệ ở đây (ví dụ: thông báo lỗi hoặc trả về giá trị mặc định)
                throw new ArgumentException("Invalid 'id' parameter", nameof(id));
            }

            var user = users.FirstOrDefault(x => x.UserId.Equals(id));

            if (user == null)
            {
                // Xử lý trường hợp không tìm thấy người dùng ở đây (ví dụ: thông báo lỗi hoặc trả về giá trị mặc định)
                throw new KeyNotFoundException($"User with ID '{id}' not found");
            }

            return user;
        }
        private string generateJwtToken(User user)
        {
            // generate token that is valid for 7 days
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_appSettings.Secret);
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[] { new Claim("id", user.UserId.ToString()) }),
                Expires = DateTime.UtcNow.AddDays(7),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }
    }
}
