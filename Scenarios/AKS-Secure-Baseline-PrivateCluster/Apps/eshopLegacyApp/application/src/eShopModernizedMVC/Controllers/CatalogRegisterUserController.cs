using eShopModernizedMVC.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using eShopModernizedMVC.Services;
using log4net;
using System.Data;
using System.Data.SqlClient;
using System.Web.Configuration;
using eShopModernizedMVC.Models;

namespace eShopModernizedMVC.Controllers
{
    public class CatalogRegisterUserController : Controller
    {
        string strCon = WebConfigurationManager.ConnectionStrings["CatalogDBContext"].ToString();
        SqlConnection con;
        SqlCommand cmd;
        private static readonly ILog _log = LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        private readonly ICatalogService _service;

        public CatalogRegisterUserController(ICatalogService service, IImageService imageService)
        {
            _service = service;
        }

        // GET: CatalogRegisterUser
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult LogIn()
        {

            return View();
        }

        [HttpPost]
        public ActionResult LogIn(CatalogRegisterUser catalogRegister)
        {
            using (con = new SqlConnection(strCon))
            {
                con.Open();
                string strCmd = "Select * from CatalogRegisterUser where firstname='" + catalogRegister.firstname + "' and password='" + catalogRegister.password + "'";
                using (cmd = new SqlCommand(strCmd, con))
                {
                    SqlDataReader dr = cmd.ExecuteReader();

                    while (dr.Read())
                    {
                        string name = dr["firstname"].ToString();
                        return RedirectToAction("Index", "Catalog");
                    }
                }
                con.Close();
            }
            ModelState.Clear();
            return View();
        }
        // GET: CatalogRegisterUser/Details/5
        public ActionResult Details(int id)
        {
            return View();
        }

        // GET: CatalogRegisterUser/Create
        public ActionResult Create()
        {
            CatalogRegisterUser catalogRegisterUsermodel = new CatalogRegisterUser();
            return View();
        }

        // POST: CatalogRegisterUser/Create
        [HttpPost]
        [Authorize]

        public ActionResult Create([Bind(Include = "id,firstname,lastname,password,confirmpassword")] CatalogRegisterUser catalogRegisterUser)
        {
            // ViewBag.Message = "User Details Saved";
            // return View("Register");
            // return RedirectToAction("Index")
            _log.Info($"Now processing... /CatalogRegisterUser/LogIn?catalogItemName={catalogRegisterUser.id}");
            if (ModelState.IsValid)
            {
                _service.CreateCatalogRegisterUser(catalogRegisterUser);

                return RedirectToAction("LogIn");
            }

            ViewBag.CatalogRegisterUserId = new SelectList(_service.GetCatalogRegisterUser(), "id", "RegisterUser", catalogRegisterUser.id);

            ViewBag.UseAzureStorage = CatalogConfiguration.UseAzureStorage;
            return View(catalogRegisterUser);
        }

        // GET: CatalogRegisterUser/Edit/5
        public ActionResult Edit(int id)
        {
            return View();
        }

        // POST: CatalogRegisterUser/Edit/5
        [HttpPost]
        public ActionResult Edit(int id, FormCollection collection)
        {
            try
            {
                // TODO: Add update logic here

                return RedirectToAction("Index");
            }
            catch
            {
                return View();
            }
        }

        // GET: CatalogRegisterUser/Delete/5
        public ActionResult Delete(int id)
        {
            return View();
        }
    }
}
