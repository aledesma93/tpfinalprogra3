// Controllers/CustomersController.cs
using Microsoft.AspNetCore.Mvc;

namespace Progra3_TPFinal_19B.Controllers
{
    public class CustomersController : Controller
    {
        public IActionResult Index() => View();
        public IActionResult Create() => View();
        public IActionResult Details(int id) => RedirectToAction(nameof(Index));
    }
}
