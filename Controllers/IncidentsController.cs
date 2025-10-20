// Controllers/IncidentsController.cs
using Microsoft.AspNetCore.Mvc;

namespace Progra3_TPFinal_19B.Controllers
{
    public class IncidentsController : Controller
    {
        public IActionResult Index() => View();
        public IActionResult Details(int id) => View();
        public IActionResult Create() => View();
        public IActionResult Resolve(int id) => View();
        public IActionResult Close(int id) => View();
        public IActionResult Reassign(int id) => View();
        public IActionResult Edit(int id) => RedirectToAction(nameof(Details), new { id });
    }
}
