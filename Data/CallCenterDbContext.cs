using Microsoft.EntityFrameworkCore;
using Progra3_TPFinal_19B.Models;

namespace Progra3_TPFinal_19B.Data
{
    public class CallCenterDbContext : DbContext
    {
        public CallCenterDbContext(DbContextOptions<CallCenterDbContext> options) : base(options) { }
        public DbSet<User> Users => Set<User>();

        protected override void OnModelCreating(ModelBuilder mb)
        {
            mb.Entity<User>(e =>
            {
                e.ToTable("Users", "dbo");
                e.HasKey(x => x.Id);

                e.Property(x => x.Id)
                    .HasColumnType("uniqueidentifier")
                    .HasDefaultValueSql("NEWID()");                 // si la tabla tiene DEFAULT, EF lo usa; si no, esto lo fuerza

                e.Property(x => x.Username).HasMaxLength(256);
                e.Property(x => x.FullName).HasMaxLength(256);
                e.Property(x => x.Role).HasMaxLength(100);

                e.Property(x => x.PasswordHash).IsRequired();

                e.Property(x => x.CreatedAt)
                    .HasDefaultValueSql("SYSUTCDATETIME()");

                e.Property(x => x.CreatedByUserId).HasColumnType("uniqueidentifier").IsRequired(false);
                e.Property(x => x.UpdatedByUserId).HasColumnType("uniqueidentifier").IsRequired(false);

                e.Property(x => x.IsDeleted).HasDefaultValue(false);

                e.Property(x => x.Email).HasMaxLength(256).IsRequired();
                e.HasIndex(x => x.Email).IsUnique();

                e.Property(x => x.IsBlocked).HasDefaultValue(false);
            });
        }
    }
}
