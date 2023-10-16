using System;
using System.Collections.Generic;

namespace SmartLocker.Models;

public partial class Otp
{
    public string OtpId { get; set; } = null!;

    public string OtpCode { get; set; } = null!;

    public DateTime ExpirationTime { get; set; }

    public string UserId { get; set; } = null!;

    public string LockerId { get; set; } = null!;

    public virtual Locker Locker { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
