// Controllers/AdminController.cs
using Microsoft.AspNetCore.Mvc;

namespace Progra3_TPFinal_19B.Controllers
{
    public class AdminController : Controller
    {
        public IActionResult Catalogs() => View();
        public IActionResult Users() => View();
        public IActionResult Settings() => View();
    }
}
