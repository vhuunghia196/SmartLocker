namespace SmartLockerAPI.Dto
{
    using System.ComponentModel.DataAnnotations;

    public class AuthenticateRequest
    {
        [Required]
        public string? Phone { get; set; }

        [Required]
        public string? Password { get; set; }
    }
}
