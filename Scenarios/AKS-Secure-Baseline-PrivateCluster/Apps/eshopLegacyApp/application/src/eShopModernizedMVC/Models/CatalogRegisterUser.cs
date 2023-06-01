using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;

namespace eShopModernizedMVC.Models
{
    public class CatalogRegisterUser
    {
        public int id { get; set; }
        [Required(AllowEmptyStrings = false, ErrorMessage = "First Name is Required.")]
        public string firstname { get; set; }

        [Required(AllowEmptyStrings = false, ErrorMessage = "Last Name is Required.")]
        public string lastname { get; set; }
        [Required(AllowEmptyStrings = false, ErrorMessage = "Password is Required.")]
        [DataType(DataType.Password)]
        public string password { get; set; }
        [Required(AllowEmptyStrings = false, ErrorMessage = "Confirm Password is Required.")]


        [Compare("password", ErrorMessage = "Password and Confirm Password should be same")]
        [DataType(DataType.Password)]
        public string confirmpassword { get; set; }

        private object catalogRegisterUser;

        public int CatalogRegisterUserId { get; set; }


        public object GetCatalogRegisterUser()
        {
            return catalogRegisterUser;
        }

        internal void SetCatalogRegisterUser(object value)
        {
            catalogRegisterUser = value;
        }
    }
}