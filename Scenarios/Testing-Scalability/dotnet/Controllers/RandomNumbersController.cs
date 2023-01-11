using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using System.Diagnostics; 

namespace SimpleApi.Controllers;

[ApiController]
[Route("[controller]")]
public class RandomNumbersController : ControllerBase
{
    private const int DefaultMillionsToGenerate = 10;
    private const int Factor = 1000000;

    private readonly ILogger<RandomNumbersController> _logger;
    private static Random random = new Random();

    private int _LazyNumbersToGenerate = -1;

    private int LazyNumbersToGenerate {
        get {
            if (_LazyNumbersToGenerate == -1) 
                _LazyNumbersToGenerate = InitializeNumbersToGenerate();
            return _LazyNumbersToGenerate;
        }
    }

    private int InitializeNumbersToGenerate()
    {
        string? toGenerate = Environment.GetEnvironmentVariable("MILLION_NUMBERS_TO_GENERATE");
        if (toGenerate != null) {
            try {
                int retVal = int.Parse(toGenerate);
                _logger.LogDebug("Creating " + retVal + " random numbers.");
                return retVal;
            } catch (Exception e) {
                _logger.LogError("Could not parse value of MILLION_NUMBERS_TO_GENERATE as string; using default value " + DefaultMillionsToGenerate + "(" + e.Message + ")");
                return DefaultMillionsToGenerate;
            }
        } else {
            _logger.LogDebug("No value of MILLION_NUMBERS_TO_GENERATE given; using default value " + DefaultMillionsToGenerate + ".");
            return DefaultMillionsToGenerate;
        }
    }

    public RandomNumbersController(ILogger<RandomNumbersController> logger)
    {
        _logger = logger;
    }

    [HttpGet(Name = "RandomNumbers")]
    public IActionResult Get([FromQuery] int numbers)
    {
        if (numbers == 0)
            numbers = LazyNumbersToGenerate;
        int toGenerate = Factor * numbers;
        Stopwatch stopWatch = new Stopwatch();
        stopWatch.Start();
        for (int i = 0 ; i < toGenerate ; i++) {
            random.Next();
        }
        stopWatch.Stop();

        return Ok(new
        {
            NumbersGenerated = toGenerate,
            TimeUsed = stopWatch.Elapsed.TotalMilliseconds
        });

    }
}
