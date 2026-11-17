using Ance.Api;
using Ance.Application;
using Ance.Application.Abstracciones;
using Ance.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

var cadena = builder.Configuration.GetConnectionString("AnceDb")
             ?? throw new InvalidOperationException("Falta la cadena de conexión AnceDb");

builder.Services.AddScoped<ISolicitudRepository>(_ => new SolicitudRepository(cadena));
builder.Services.AddScoped<SolicitudService>();

builder.Services.AddExceptionHandler<ManejadorErrores>();
builder.Services.AddProblemDetails();

builder.Services.AddControllers()
    .ConfigureApiBehaviorOptions(o => o.InvalidModelStateResponseFactory = _ =>
        new Microsoft.AspNetCore.Mvc.BadRequestObjectResult(
            new { code = "SOLICITUD_INVALIDA", message = "El formato de la petición no es válido" }));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseDefaultFiles();
app.UseStaticFiles();

app.MapControllers();
app.Run();