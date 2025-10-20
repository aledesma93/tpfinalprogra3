namespace Progra3_TPFinal_19B.Models
{
    public class User
    {
        public Guid Id { get; set; }                   
        public string Username { get; set; } = null!;
        public string? FullName { get; set; }
        public string? Role { get; set; }
        public string PasswordHash { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
        public Guid? CreatedByUserId { get; set; }    
        public DateTime? UpdatedAt { get; set; }
        public Guid? UpdatedByUserId { get; set; }    
        public bool IsDeleted { get; set; }
        public string Email { get; set; } = null!;
        public bool IsBlocked { get; set; }
    }
}
