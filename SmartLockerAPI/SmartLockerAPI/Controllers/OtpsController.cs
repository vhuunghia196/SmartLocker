using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Humanizer;
using MailKit.Net.Smtp;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using MimeKit;
using NuGet.Versioning;
using OtpSharp;
using SmartLocker.Data;
using SmartLocker.Models;
using SmartLockerAPI.Helpers;
using SmartLockerAPI.Models;
using SmartLockerAPI.Services;
using Otp = SmartLocker.Models.Otp;
using Vonage;
using Vonage.Request;
using SmartLockerAPI.Dto;

namespace SmartLockerAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OtpsController : ControllerBase
    {
        private readonly SmartLockerContext _context;
        private readonly AppSettings _appSettings;
        private TokenService _tokenService;
        private static List<OtpSecretKey> _secretKeys = new List<OtpSecretKey>();

        public OtpsController(SmartLockerContext context, IOptions<AppSettings> appSettings, TokenService tokenService)
        {
            _context = context;
            _appSettings = appSettings.Value;
            _tokenService = tokenService;
        }

        [Authorize]
        // GET: api/Otps
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Otp>>> GetOtps()
        {
            if (_context.Otps == null)
            {
                return NotFound();
            }
            return await _context.Otps.ToListAsync();
        }

        [Authorize]
        // GET: api/Otps/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Otp>> GetOtp(string id)
        {
            if (_context.Otps == null)
            {
                return NotFound();
            }
            var otp = await _context.Otps.FindAsync(id);

            if (otp == null)
            {
                return NotFound();
            }

            return otp;
        }

        [Authorize]
        // PUT: api/Otps/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutOtp(string id, Otp otp)
        {
            if (id != otp.OtpId)
            {
                return BadRequest();
            }

            _context.Entry(otp).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!OtpExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        [Authorize]
        // POST: api/Otps
        [HttpPost]
        public async Task<ActionResult<Otp>> PostOtp(PostOtp data)
        {
            if (_context.Otps == null)
            {
                return Problem("Entity set 'SmartLockerContext.Otps'  is null.");
            }
            Otp otp = _context.Otps.FirstOrDefault(o => o.OtpCode.Equals(data.otp));
            if (otp == null)
            {
                return NotFound(new { message = "Can't find otp" });
            }
            otp.LockerId = data.lockerId;
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                if (OtpExists(otp.OtpId))
                {
                    return Conflict();
                }
                else
                {
                    throw;
                }
            }

            return CreatedAtAction("GetOtp", new { id = otp.OtpId }, otp);
        }

        [Authorize]
        [HttpGet("getbyuserid/{userId}")]
        public async Task<IActionResult> getOtpByUserId(string userId)
        {
            if (_context.Otps == null)
            {
                return NotFound();
            }
            var otp = _context.Otps.Where(x => x.UserId == userId).ToList();
            if (otp == null)
            {
                return NotFound();
            }
            return Ok(new { otp = otp });
        }


        [Authorize]
        // DELETE: api/Otps/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteOtp(string id)
        {
            if (_context.Otps == null)
            {
                return NotFound();
            }
            var otp = _context.Otps.Find(id);
            if (otp == null)
            {
                return NotFound();
            }

            _context.Otps.Remove(otp);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool OtpExists(string id)
        {
            return (_context.Otps?.Any(e => e.OtpId == id)).GetValueOrDefault();
        }

        [Authorize]
        [HttpPost("generatedotp")]
        public IActionResult GenerateOtp([FromBody] OtpData data)
        {
            var token = HttpContext.Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
            var userId = GetUserIdFromToken(token);

            if (userId == null)
            {
                return BadRequest("Invalid token");
            }

            var history = FindHistory(data);
            if (history == null)
            {
                return NotFound(new { message = "Don't have any order" });
            }

            var user = GetUser(data, userId);
            if (user == null)
            {
                return Unauthorized(new { title = "No user login" });
            }

            var otpCode = GenerateOtpCode();
            var otp = SaveOtp(otpCode, user, history);

            return Ok(new { otp = otp, historyId = history.HistoryId });
        }

        private string GetUserIdFromToken(string token)
        {
            byte[] secretKey = Encoding.ASCII.GetBytes(_appSettings.Secret);
            return _tokenService.GetUserIdFromToken(token, secretKey);
        }

        private History FindHistory(OtpData data)
        {
            Random random = new Random();
            History history;
            if (data.UserIdReceive == null)
            {
                var listHistories = _context.Histories.Where(x => x.StartTime == data.StartTime && x.UserSend == null && x.Locker.Location == data.LocationSend).ToList();
                if (listHistories.Any())
                {
                    // Nếu có ít nhất một History thích hợp, chọn một ngẫu nhiên
                    int randomIndex;
                    randomIndex = random.Next(listHistories.Count);
                    history = listHistories[randomIndex];
                    return history;
                }
                return null;
            }
            else
            {
                var tmp = _context.Histories.FirstOrDefault(x => x.Shipper == data.UserIdReceive && x.StartTime == data.StartTime && x.Locker.Location == data.LocationSend);
                if (tmp != null)
                {
                    var listHistories = _context.Histories.Where(x => x.StartTime == data.StartTime && x.UserSend == null && x.Locker.Location == data.LocationReceive).ToList();
                    if (listHistories.Any())
                    {
                        // Nếu có ít nhất một History thích hợp, chọn một ngẫu nhiên
                        int randomIndex;
                        randomIndex = random.Next(listHistories.Count);
                        history = listHistories[randomIndex];
                        return history;
                    }
                }
                var tmp2 = _context.Histories.FirstOrDefault(x => x.Shipper == data.UserIdSend && x.StartTime == data.StartTime && x.Locker.Location == data.LocationReceive);
                if (tmp2 != null)
                {
                    return tmp2;
                }
            }
            return null;
        }

        private User GetUser(OtpData data, string userId)
        {
            if (data.UserIdReceive != null)
            {
                return _context.Users.Find(data.UserIdReceive);
            }
            else
            {
                return _context.Users.Find(data.UserIdSend);
            }
        }

        private string GenerateOtpCode()
        {
            byte[] newSecretKey = Encoding.UTF8.GetBytes(GenerateRandomString(50));
            var totp = new Totp(newSecretKey, step: 10800);
            return totp.ComputeTotp(DateTime.UtcNow);
        }

        private Otp SaveOtp(string otpCode, User user, History history)
        {
            Guid guid = Guid.NewGuid();
            Otp otp = new Otp
            {
                OtpId = guid.ToString(),
                OtpCode = otpCode,
                ExpirationTime = DateTime.Now.AddHours(3),
                UserId = user.UserId,
                LockerId = history.LockerId
            };

            _context.Otps.Add(otp);
            _context.SaveChanges();

            return otp;
        }


        [Authorize]
        [HttpPost("sendmail")]
        public async Task<IActionResult> SendMail([FromBody] MailData mailData)
        {
            if (mailData.UserId == null) return BadRequest();
            var user = _context.Users.Find(mailData.UserId);
            if (user == null) return BadRequest();
            try
            {
                var message = new MimeMessage();
                message.From.Add(new MailboxAddress("SmartLocker", "smartlocker894@gmail.com"));
                message.To.Add(new MailboxAddress(user.Name, user.Mail));
                message.Subject = "You have request on SmartLocker";

                string messageText = mailData.MailContent;

                message.Body = new TextPart("plain")
                {
                    Text = messageText
                };


                using (var client = new SmtpClient())
                {
                    await client.ConnectAsync("smtp.gmail.com", 587, false); // SMTP server và cổng
                    await client.AuthenticateAsync("smartlocker894@gmail.com", "mmlc clpt nhal xnwn"); // Tên đăng nhập và mật khẩu email của bạn
                    await client.SendAsync(message);
                    await client.DisconnectAsync(true);
                }

                return Ok("Email sent successfully.");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Email sending failed: {ex.Message}");
            }
        }

        static string GenerateRandomString(int length)
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
            Random random = new Random();
            StringBuilder stringBuilder = new StringBuilder(length);

            for (int i = 0; i < length; i++)
            {
                int index = random.Next(chars.Length);
                char randomChar = chars[index];
                stringBuilder.Append(randomChar);
            }

            return stringBuilder.ToString();
        }

        [Authorize]
        [HttpPost("sendsms")]
        public async Task<IActionResult> SendSMS([FromBody] MailData mailData)
        {
            var credentials = Credentials.FromApiKeyAndSecret(
                            "9e589e6e",
                            "YOSL7eg3RqUx0Y3d"
                            );

            var VonageClient = new VonageClient(credentials);
            var response = VonageClient.SmsClient.SendAnSms(new Vonage.Messaging.SendSmsRequest()
            {
                To = "84899256655",
                From = "SmartLocker",
                Text = mailData.MailContent
            });
            return Ok("Send sms successfull!");
        }
    }
}