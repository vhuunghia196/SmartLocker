namespace SmartLockerAPI.Models
{
    using System.ComponentModel.DataAnnotations;
    public class OtpSecretKey
    {
        [Required]
        public string? otp;
        [Required]
        public byte[]? secretKey;

        public OtpSecretKey(byte[] secretKey, string otp)
        {
            this.secretKey = secretKey;
            this.otp = otp;
        }
    }
}
