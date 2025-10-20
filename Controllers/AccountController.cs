using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Progra3_TPFinal_19B.Data;
using Progra3_TPFinal_19B.Models;

[AllowAnonymous]
public class AccountController : Controller
{
    private readonly CallCenterDbContext _db;
    private readonly IPasswordHasher<User> _hasher;

    public AccountController(CallCenterDbContext db, IPasswordHasher<User> hasher)
    { _db = db; _hasher = hasher; }

    [HttpGet]
    public IActionResult Login(string? returnUrl = null)
    {
        ViewData["ReturnUrl"] = returnUrl;
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(string email, string password, bool rememberMe, string? returnUrl = null)
    {
        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Email == email);
        if (user is null)
        {
            ModelState.AddModelError("", "Email no registrado.");
            ViewData["ReturnUrl"] = returnUrl; return View();
        }
        if (user.IsBlocked)
        {
            ModelState.AddModelError("", "Usuario bloqueado.");
            ViewData["ReturnUrl"] = returnUrl; return View();
        }

        var result = _hasher.VerifyHashedPassword(user, user.PasswordHash, password);
        if (result == PasswordVerificationResult.Failed)
        {
            ModelState.AddModelError("", "Contraseña incorrecta.");
            ViewData["ReturnUrl"] = returnUrl; return View();
        }

        var claims = new List<Claim> {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Name, user.FullName ?? user.Email),
            new(ClaimTypes.Email, user.Email),
            new(ClaimTypes.Role, user.Role ?? "User")
        };
        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity),
            new AuthenticationProperties { IsPersistent = rememberMe });

        return Redirect(returnUrl ?? Url.Action("Index", "Home")!);
    }

    [HttpGet]
    public IActionResult Register(string? returnUrl = null)
    { ViewData["ReturnUrl"] = returnUrl; return View(); }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [AllowAnonymous]
    public async Task<IActionResult> Register(string email, string password, string confirmPassword, string? returnUrl = null)
    {
        if (password != confirmPassword) { ModelState.AddModelError("", "Las contraseñas no coinciden."); ViewData["ReturnUrl"] = returnUrl; return View(); }
        if (await _db.Users.AnyAsync(u => u.Email == email)) { ModelState.AddModelError("", "El email ya está registrado."); ViewData["ReturnUrl"] = returnUrl; return View(); }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = email,
            FullName = email,
            Email = email,
            Role = "Telefonista", // o el permitido por tu CHECK
            IsBlocked = false,
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow,
            CreatedByUserId = null
        };
        user.PasswordHash = _hasher.HashPassword(user, password);

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        TempData["RegisterOk"] = "Cuenta creada con éxito. Iniciá sesión para continuar.";
        return RedirectToAction(nameof(Login), new { returnUrl });
    }


    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Logout()
    { await HttpContext.SignOutAsync(); return RedirectToAction(nameof(Login)); }

    [HttpGet]
    public IActionResult AccessDenied() => View();
}
