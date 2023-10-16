using Newtonsoft.Json;
using System;
using System.Collections.Generic;

namespace SmartLocker.Models;

public partial class User
{
    public string UserId { get; set; } = null!;

    public string Name { get; set; } = null!;

    public string Mail { get; set; } = null!;

    public string Phone { get; set; } = null!;

    public string RoleId { get; set; } = null!;

    [JsonIgnore]
    public string Password { get; set; } = null!;

    public virtual ICollection<History> Histories { get; set; } = new List<History>();

    public virtual ICollection<Otp> Otps { get; set; } = new List<Otp>();

    public virtual Role? Role { get; set; }
}
