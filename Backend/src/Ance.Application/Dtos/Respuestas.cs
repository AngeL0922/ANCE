namespace Ance.Application.Dtos;

public class SolicitudResumenDto
{
    public int Id { get; set; }
    public string Folio { get; set; } = "";
    public string Titulo { get; set; } = "";
    public string Solicitante { get; set; } = "";
    public int PrioridadId { get; set; }
    public string Prioridad { get; set; } = "";
    public int? ResponsableId { get; set; }
    public string? Responsable { get; set; }
    public int EstadoId { get; set; }
    public string Estado { get; set; } = "";
    public DateTime FechaCreacion { get; set; }
}

public class SolicitudDetalleDto
{
    public int Id { get; set; }
    public string Folio { get; set; } = "";
    public string Titulo { get; set; } = "";
    public string Solicitante { get; set; } = "";
    public int PrioridadId { get; set; }
    public string Prioridad { get; set; } = "";
    public int? ResponsableId { get; set; }
    public string? Responsable { get; set; }
    public int EstadoId { get; set; }
    public string Estado { get; set; } = "";
    public DateTime FechaCreacion { get; set; }
    public string Correo { get; set; } = "";
    public int TipoSolicitudId { get; set; }
    public string TipoSolicitud { get; set; } = "";
    public string Descripcion { get; set; } = "";
    public string? ComentarioResolucion { get; set; }
    public DateTime? FechaActualizacion { get; set; }
}

public class HistorialDto
{
    public long Id { get; set; }
    public DateTime Fecha { get; set; }
    public int TipoAccionId { get; set; }
    public string Accion { get; set; } = "";
    public string? EstadoAnterior { get; set; }
    public string? EstadoNuevo { get; set; }
    public string? ResponsableAnterior { get; set; }
    public string? ResponsableNuevo { get; set; }
    public string Detalle { get; set; } = "";
}

public class ElementoCatalogoDto 
{
    public int Id { get; set; }
    public string Nombre { get; set; } = "";
}

public class CatalogosDto
{
    public List<ElementoCatalogoDto> Estados { get; set; } = new();
    public List<ElementoCatalogoDto> Prioridades { get; set; } = new();
    public List<ElementoCatalogoDto> Tipos { get; set; } = new();
    public List<ElementoCatalogoDto> Responsables { get; set; } = new();
    public List<int[]> Transiciones { get; set; } = new();
}