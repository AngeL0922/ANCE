let catalogos = { estados: [], prioridades: [], tipos: [], responsables: [], transiciones: [] };

async function api(ruta, opciones = {}) {
    const respuesta = await fetch('/api' + ruta, {
        headers: { 'Content-Type': 'application/json' },
        ...opciones
    });
    if (respuesta.status === 204) return null;
    const datos = await respuesta.json().catch(() => null);
    if (!respuesta.ok) throw new Error(datos?.message ?? `Error ${respuesta.status}`);
    return datos;
}

function esc(texto) {
    const div = document.createElement('div');
    div.textContent = texto ?? '';
    return div.innerHTML;
}

function fecha(iso) {
    return iso ? new Date(iso).toLocaleString('es-MX') : '—';
}

function nombreEstado(id) {
    return catalogos.estados.find(e => e.id === id)?.nombre ?? '';
}

function mostrarAviso(texto, tipo = 'error') {
    const aviso = document.getElementById('aviso');
    aviso.textContent = texto;
    aviso.className = `aviso ${tipo}`;
}

function ocultarAviso() {
    document.getElementById('aviso').className = 'aviso oculto';
}

function llenarSelect(select, lista) {
    lista.forEach(e => select.insertAdjacentHTML('beforeend', `<option value="${e.id}">${esc(e.nombre)}</option>`));
}

function mostrarVista(nombre) {
    document.querySelectorAll('.vista').forEach(v => v.classList.toggle('oculto', v.id !== `vista-${nombre}`));
}

async function router() {
    const hash = location.hash;
    try {
        if (hash === '#/nueva') {
            mostrarVista('nueva');
        } else if (hash.startsWith('#/solicitud/')) {
            mostrarVista('detalle');
            await cargarDetalle(Number(hash.split('/')[2]));
        } else {
            mostrarVista('listado');
            await cargarListado();
        }
    } catch (error) {
        mostrarAviso(error.message);
    }
}

async function cargarListado() {
    const estado = document.getElementById('filtro-estado').value;
    const solicitudes = await api('/solicitudes' + (estado ? `?estadoId=${estado}` : ''));
    const tabla = document.getElementById('tabla-solicitudes');

    tabla.innerHTML = solicitudes.map(s => `
        <tr onclick="location.hash='#/solicitud/${s.id}'">
            <td>${esc(s.folio)}</td>
            <td>${esc(s.titulo)}</td>
            <td>${esc(s.solicitante)}</td>
            <td>${esc(s.prioridad)}</td>
            <td>${esc(s.responsable ?? 'Sin asignar')}</td>
            <td><span class="estado estado-${s.estadoId}">${esc(s.estado)}</span></td>
            <td>${fecha(s.fechaCreacion)}</td>
        </tr>`).join('');

    document.getElementById('sin-resultados').classList.toggle('oculto', solicitudes.length > 0);
}

function validarFormulario(datos) {
    const errores = {};

    if (!datos.solicitante?.trim()) errores.solicitante = 'El solicitante es obligatorio';

    if (!datos.correo?.trim()) errores.correo = 'El correo es obligatorio';
    else if (!/^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/.test(datos.correo.trim())) errores.correo = 'El correo no tiene un formato válido';

    if (!datos.tipoSolicitudId) errores.tipoSolicitudId = 'El tipo de solicitud es obligatorio';

    if (!datos.titulo?.trim()) errores.titulo = 'El título es obligatorio';
    else if (datos.titulo.trim().length > 150) errores.titulo = 'El título no puede exceder 150 caracteres';

    if (!datos.descripcion?.trim()) errores.descripcion = 'La descripción es obligatoria';

    return errores;
}

async function registrar(evento) {
    evento.preventDefault();
    ocultarAviso();
    const form = evento.target;
    const datos = Object.fromEntries(new FormData(form));
    const errores = validarFormulario(datos);

    form.querySelectorAll('.error').forEach(e => e.textContent = errores[e.dataset.campo] ?? '');
    if (Object.keys(errores).length > 0) return;

    try {
        const creada = await api('/solicitudes', {
            method: 'POST',
            body: JSON.stringify({
                solicitante: datos.solicitante.trim(),
                correo: datos.correo.trim(),
                tipoSolicitudId: Number(datos.tipoSolicitudId),
                prioridadId: Number(datos.prioridadId),
                responsableId: datos.responsableId ? Number(datos.responsableId) : null,
                titulo: datos.titulo.trim(),
                descripcion: datos.descripcion.trim()
            })
        });
        form.reset();
        location.hash = `#/solicitud/${creada.id}`;
        mostrarAviso(`Solicitud ${creada.folio} registrada.`, 'exito');
    } catch (error) {
        mostrarAviso(error.message);
    }
}

async function cargarDetalle(id) {
    const [s, historial] = await Promise.all([api(`/solicitudes/${id}`), api(`/solicitudes/${id}/historial`)]);
    const esFinal = s.estadoId === 4 || s.estadoId === 5;

    document.getElementById('det-titulo').textContent = `${s.folio} · ${s.titulo}`;
    document.getElementById('det-datos').innerHTML = `
        <dt>Estado</dt><dd><span class="estado estado-${s.estadoId}">${esc(s.estado)}</span></dd>
        <dt>Solicitante</dt><dd>${esc(s.solicitante)}</dd>
        <dt>Correo</dt><dd>${esc(s.correo)}</dd>
        <dt>Tipo</dt><dd>${esc(s.tipoSolicitud)}</dd>
        <dt>Prioridad</dt><dd>${esc(s.prioridad)}</dd>
        <dt>Responsable</dt><dd>${esc(s.responsable ?? 'Sin asignar')}</dd>
        <dt>Fecha de creación</dt><dd>${fecha(s.fechaCreacion)}</dd>
        <dt>Descripción</dt><dd>${esc(s.descripcion)}</dd>
        ${s.comentarioResolucion ? `<dt>Resolución</dt><dd>${esc(s.comentarioResolucion)}</dd>` : ''}`;

    const selResp = document.getElementById('sel-responsable');
    selResp.innerHTML = '<option value="">Selecciona…</option>';
    llenarSelect(selResp, catalogos.responsables.filter(r => r.id !== s.responsableId));
    document.querySelectorAll('#form-asignar select, #form-asignar button').forEach(e => e.disabled = esFinal);
    document.getElementById('form-asignar').onsubmit = async evento => {
        evento.preventDefault();
        if (!selResp.value) return;
        await ejecutar(() => api(`/solicitudes/${id}/responsable`, {
            method: 'PUT', body: JSON.stringify({ responsableId: Number(selResp.value) })
        }), id, 'Responsable asignado.');
    };

    const acciones = document.getElementById('acciones-estado');
    const comentario = document.getElementById('comentario');
    comentario.value = '';
    comentario.classList.toggle('oculto', esFinal);
    acciones.innerHTML = esFinal ? '<p>Estado final: ya no admite cambios.</p>' : '';

    catalogos.transiciones
        .filter(([origen]) => origen === s.estadoId)
        .forEach(([, destino]) => {
            const boton = document.createElement('button');
            boton.className = destino === 5 ? 'boton peligro' : 'boton';
            boton.textContent = `Pasar a ${nombreEstado(destino)}`;
            if (destino === 2 && !s.responsableId) {
                boton.disabled = true;
                boton.title = 'Asigna un responsable primero.';
            }
            boton.onclick = async () => {
                if (destino === 3 && !comentario.value.trim()) {
                    mostrarAviso('Escribe el comentario de resolución.');
                    return;
                }
                await ejecutar(() => api(`/solicitudes/${id}/estado`, {
                    method: 'PATCH', body: JSON.stringify({ estadoId: destino, comentario: comentario.value.trim() || null })
                }), id, `Estado cambiado a ${nombreEstado(destino)}.`);
            };
            acciones.appendChild(boton);
        });

    document.getElementById('historial').innerHTML = historial
        .map(h => `<li><time>${fecha(h.fecha)}</time><strong>${esc(h.accion)}</strong> — ${esc(h.detalle)}</li>`)
        .join('');
}

async function ejecutar(accion, id, mensajeExito) {
    try {
        await accion();
        await cargarDetalle(id);
        mostrarAviso(mensajeExito, 'exito');
    } catch (error) {
        mostrarAviso(error.message);
    }
}

async function iniciar() {
    try {
        catalogos = await api('/catalogos');
    } catch (error) {
        mostrarAviso('No se pudieron cargar los catálogos: ' + error.message);
        return;
    }
    llenarSelect(document.getElementById('filtro-estado'), catalogos.estados);
    llenarSelect(document.getElementById('sel-tipo'), catalogos.tipos);
    llenarSelect(document.getElementById('sel-prioridad'), catalogos.prioridades);
    llenarSelect(document.getElementById('sel-responsable-nuevo'), catalogos.responsables);
    document.getElementById('sel-prioridad').value = '2';

    document.getElementById('filtro-estado').addEventListener('change', () => cargarListado().catch(e => mostrarAviso(e.message)));
    document.getElementById('form-nueva').addEventListener('submit', registrar);
    window.addEventListener('hashchange', () => { ocultarAviso(); router(); });
    router();
}

iniciar();