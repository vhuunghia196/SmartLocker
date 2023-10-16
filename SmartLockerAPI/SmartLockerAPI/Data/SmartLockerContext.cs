using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using SmartLocker.Models;

namespace SmartLocker.Data;

public partial class SmartLockerContext : DbContext
{
    public SmartLockerContext(DbContextOptions<SmartLockerContext> options)
        : base(options)
    {
    }

    public virtual DbSet<History> Histories { get; set; }

    public virtual DbSet<Locker> Lockers { get; set; }

    public virtual DbSet<Otp> Otps { get; set; }

    public virtual DbSet<Role> Roles { get; set; }

    public virtual DbSet<User> Users { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder
            .UseCollation("utf8mb4_unicode_ci")
            .HasCharSet("utf8mb4");

        modelBuilder.Entity<History>(entity =>
        {
            entity.HasKey(e => e.HistoryId).HasName("PRIMARY");

            entity.ToTable("histories");

            entity.HasIndex(e => e.LockerId, "fk_histories_lockers_idx");

            entity.HasIndex(e => e.UserSend, "fk_histories_users_idx");

            entity.Property(e => e.HistoryId)
                .HasMaxLength(45)
                .HasColumnName("history_id");
            entity.Property(e => e.EndTime)
                .HasMaxLength(45)
                .HasColumnName("end_time");
            entity.Property(e => e.LockerId)
                .HasMaxLength(45)
                .HasColumnName("locker_id");
            entity.Property(e => e.StartTime)
                .HasMaxLength(45)
                .HasColumnName("start_time");
            entity.Property(e => e.UserSend)
                .HasMaxLength(45)
                .HasColumnName("user_send");
            entity.Property(e => e.Shipper)
                .HasMaxLength(45)
                .HasColumnName("shipper");
            entity.Property(e => e.Receiver)
                .HasMaxLength(45)
                .HasColumnName("receiver");

            entity.HasOne(d => d.Locker).WithMany(p => p.Histories)
                .HasForeignKey(d => d.LockerId)
                .HasConstraintName("fk_histories_lockers_idx");

            entity.HasOne(d => d.User).WithMany(p => p.Histories)
                .HasForeignKey(d => d.UserSend)
                .HasConstraintName("fk_histories_users_idx");
        });

        modelBuilder.Entity<Locker>(entity =>
        {
            entity.HasKey(e => e.LockerId).HasName("PRIMARY");

            entity.ToTable("lockers");

            entity.HasIndex(e => e.LockerId, "locker_id_UNIQUE").IsUnique();

            entity.Property(e => e.LockerId)
                .HasMaxLength(45)
                .HasColumnName("locker_id");
            entity.Property(e => e.Location)
                .HasMaxLength(45)
                .HasColumnName("location");
            entity.Property(e => e.Status)
                .HasColumnType("enum('on','off')")
                .HasColumnName("status");
        });

        modelBuilder.Entity<Otp>(entity =>
        {
            entity.HasKey(e => e.OtpId).HasName("PRIMARY");

            entity.ToTable("otps");

            entity.HasIndex(e => e.LockerId, "fk_otps_lockers_idx");

            entity.HasIndex(e => e.UserId, "fk_otps_users_idx");

            entity.HasIndex(e => e.OtpCode, "otp_code_UNIQUE").IsUnique();

            entity.HasIndex(e => e.OtpId, "otp_id_UNIQUE").IsUnique();

            entity.Property(e => e.OtpId)
                .HasMaxLength(45)
                .HasColumnName("otp_id");
            entity.Property(e => e.ExpirationTime)
                .HasColumnType("datetime")
                .HasColumnName("expiration_time");
            entity.Property(e => e.LockerId)
                .HasMaxLength(45)
                .HasColumnName("locker_id");
            entity.Property(e => e.OtpCode)
                .HasMaxLength(10)
                .HasColumnName("otp_code");
            entity.Property(e => e.UserId)
                .HasMaxLength(45)
                .HasColumnName("user_id");

            entity.HasOne(d => d.Locker).WithMany(p => p.Otps)
                .HasForeignKey(d => d.LockerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("fk_otps_lockers_idx");

            entity.HasOne(d => d.User).WithMany(p => p.Otps)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("fk_otps_users_idx");
        });

        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(e => e.RoleId).HasName("PRIMARY");

            entity.ToTable("roles");

            entity.HasIndex(e => e.RoleId, "role_id_UNIQUE").IsUnique();

            entity.Property(e => e.RoleId)
                .HasMaxLength(45)
                .HasColumnName("role_id");
            entity.Property(e => e.Description)
                .HasMaxLength(255)
                .HasColumnName("description");
            entity.Property(e => e.RoleName)
                .HasMaxLength(45)
                .HasColumnName("role_name");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserId).HasName("PRIMARY");

            entity.ToTable("users");

            entity.HasIndex(e => e.RoleId, "fk_users_roles_idx");

            entity.HasIndex(e => e.UserId, "user_id_UNIQUE").IsUnique();

            entity.Property(e => e.UserId)
                .HasMaxLength(45)
                .HasColumnName("user_id");
            entity.Property(e => e.Mail)
                .HasMaxLength(45)
                .HasColumnName("mail");
            entity.Property(e => e.Name)
                .HasMaxLength(45)
                .HasColumnName("name");
            entity.Property(e => e.Password)
                .HasMaxLength(45)
                .HasColumnName("password");
            entity.Property(e => e.Phone)
                .HasMaxLength(45)
                .HasColumnName("phone");
            entity.Property(e => e.RoleId)
                .HasMaxLength(45)
                .HasColumnName("role_id");

            entity.HasOne(d => d.Role).WithMany(p => p.Users)
                .HasForeignKey(d => d.RoleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("fk_users_roles_idx");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
