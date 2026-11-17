using Ance.Application;
using Ance.Application.Dtos;
using Microsoft.AspNetCore.Mvc;

namespace Ance.Api.Controllers;

[ApiController]
[Route("api/solicitudes")]
public class SolicitudesController : ControllerBase
{
    private readonly SolicitudService _servicio;

    public SolicitudesController(SolicitudService servicio)
    {
        _servicio = servicio;
    }

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] int? estadoId) =>
        Ok(await _servicio.ListarAsync(estadoId));

    [HttpGet("{id:int}")]
    public async Task<IActionResult> ObtenerPorId(int id) =>
        Ok(await _servicio.ObtenerPorIdAsync(id));

    [HttpPost]
    public async Task<IActionResult> Crear([FromBody] CrearSolicitudRequest datos)
    {
        var creada = await _servicio.CrearAsync(datos);
        return CreatedAtAction(nameof(ObtenerPorId), new { id = creada.Id }, creada);
    }

    [HttpPut("{id:int}/responsable")]
    public async Task<IActionResult> AsignarResponsable(int id, [FromBody] AsignarResponsableRequest datos)
    {
        await _servicio.AsignarResponsableAsync(id, datos);
        return NoContent();
    }

    [HttpPatch("{id:int}/estado")]
    public async Task<IActionResult> CambiarEstado(int id, [FromBody] CambiarEstadoRequest datos)
    {
        await _servicio.CambiarEstadoAsync(id, datos);
        return NoContent();
    }

    [HttpGet("{id:int}/historial")]
    public async Task<IActionResult> Historial(int id) =>
        Ok(await _servicio.ListarHistorialAsync(id));
    
    [HttpGet("/api/catalogos")]
    public async Task<IActionResult> Catalogos() =>
        Ok(await _servicio.ObtenerCatalogosAsync());
}