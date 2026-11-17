using Ance.Application.Dtos;

namespace Ance.Application.Abstracciones;

public interface ISolicitudRepository
{
    Task<List<SolicitudResumenDto>> ListarAsync(int? estadoId);
    Task<SolicitudDetalleDto?> ObtenerPorIdAsync(int id);
    Task<SolicitudDetalleDto> CrearAsync(CrearSolicitudRequest datos);
    Task AsignarResponsableAsync(int id, int responsableId);
    Task CambiarEstadoAsync(int id, int estadoId, string? comentario);
    Task<List<HistorialDto>> ListarHistorialAsync(int id);
    Task<CatalogosDto> ObtenerCatalogosAsync();
}