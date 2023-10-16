using System;
using System.Collections.Generic;

namespace SmartLocker.Models;

public partial class Locker
{
    public string LockerId { get; set; } = null!;

    public string? Location { get; set; }

    public string Status { get; set; } = null!;

    public virtual ICollection<History> Histories { get; set; } = new List<History>();

    public virtual ICollection<Otp> Otps { get; set; } = new List<Otp>();
}
