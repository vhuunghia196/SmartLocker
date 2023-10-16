namespace SmartLockerAPI.Services
{
    using System;
    using System.IdentityModel.Tokens.Jwt;
    using System.Security.Claims;
    using Microsoft.IdentityModel.Tokens;

    public class TokenService
    {
        public ClaimsPrincipal GetPrincipalFromToken(string token, Byte[] secretKey)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            try
            {
                var validationParameters = new TokenValidationParameters
                {
                    IssuerSigningKey = new SymmetricSecurityKey(secretKey),
                    ValidateIssuer = false,
                    ValidateAudience = false
                };

                var principal = tokenHandler.ValidateToken(token, validationParameters, out var securityToken);

                if (securityToken is not JwtSecurityToken jwtSecurityToken || !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
                {
                    return null;
                }

                return principal;
            }
            catch
            {
                return null;
            }
        }
        public string GetUserIdFromToken(string token, byte[] secretKey)
        {
            var principal = GetPrincipalFromToken(token, secretKey);

            if (principal == null)
            {
                return null;
            }

            // Extract user ID claim from the principal
            var userIdClaim = principal.Claims.ElementAt(0).Value;

            if (userIdClaim == null)
            {
                return null;
            }

            return userIdClaim;
        }
    }
}
