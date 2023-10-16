using Microsoft.EntityFrameworkCore;
using SmartLocker.Data;
using SmartLockerAPI.Helpers;
using SmartLockerAPI.Services;
using System.Configuration;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
//builder.Services.AddDbContext<SmartLockerContext>(options =>
    //options.UseMySQL("Server=localhost;port=3307;Database=smart-locker;User Id=root;Password=0979620120@Hau;", mysqlOptions => mysqlOptions.EnableRetryOnFailure()));

builder.Services.AddDbContext<SmartLockerContext>(options =>
options.UseMySQL("Server=localhost;port=3306;Database=smart-locker;User Id=root;Password=123456;", mysqlOptions => mysqlOptions.EnableRetryOnFailure()));
builder.Services.AddCors();
builder.Services.Configure<AppSettings>(builder.Configuration.GetSection("AppSettings"));
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<TokenService, TokenService>();
builder.Services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();
builder.Services.AddMvc()
                .AddJsonOptions(opt =>
                {
                    opt.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.Preserve;
                });

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors(x => x
        .AllowAnyOrigin()
        .AllowAnyMethod()
        .AllowAnyHeader());

// custom jwt auth middleware
app.UseMiddleware<JwtMiddleware>();

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
