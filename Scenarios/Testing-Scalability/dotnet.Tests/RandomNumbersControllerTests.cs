using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using SimpleApi.Controllers;

namespace SimpleApi.Tests;

public class RandomNumbersControllerTests
{
    [Fact]
    public void Get_WhenNumbersIsNegative_ReturnsBadRequest()
    {
        var logger = new LoggerFactory().CreateLogger<RandomNumbersController>();
        var controller = new RandomNumbersController(logger);

        var result = controller.Get(-1);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        Assert.Equal("numbers must be greater than zero.", badRequest.Value);
    }

    [Fact]
    public void Get_WhenNumbersIsZero_UsesDefaultValue()
    {
        var logger = new LoggerFactory().CreateLogger<RandomNumbersController>();
        var controller = new RandomNumbersController(logger);

        var result = controller.Get(0);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(ok.Value);
    }

    [Fact]
    public void Get_WhenNumbersIsTooLarge_ReturnsBadRequest()
    {
        var logger = new LoggerFactory().CreateLogger<RandomNumbersController>();
        var controller = new RandomNumbersController(logger);

        var result = controller.Get(1000000);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        Assert.Contains("must be less than or equal to", badRequest.Value?.ToString());
    }
}
