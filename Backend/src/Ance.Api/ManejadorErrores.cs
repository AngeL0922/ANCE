using Ance.Application.Excepciones;
using Microsoft.AspNetCore.Diagnostics;

namespace Ance.Api;

public class ManejadorErrores : IExceptionHandler
{
    private readonly ILogger<ManejadorErrores> _logger;

    public ManejadorErrores(ILogger<ManejadorErrores> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(HttpContext http, Exception ex, CancellationToken ct)
    {
        int status;
        object respuesta;

        if (ex is NegocioException negocio)
        {
            status = negocio.StatusCode;
            respuesta = new { code = negocio.Codigo, message = negocio.Message };
            _logger.LogWarning("Error de negocio {Codigo}: {Mensaje}", negocio.Codigo, negocio.Message);
        }
        else
        {
            status = 500;
            respuesta = new { code = "ERROR_INTERNO", message = "Ocurrió un error inesperado." };
            _logger.LogError(ex, "Error no controlado en {Ruta}", http.Request.Path);
        }

        http.Response.StatusCode = status;
        await http.Response.WriteAsJsonAsync(respuesta, ct);
        return true;
    }
}