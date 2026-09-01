enum ModoVisualizacion { individual, grupoEspecifico, nivelEducativo, general }

/// Mapea el código guardado en 'seccion' (ej. 'AlumnosSalon', 'Todos') al modo de vista.
ModoVisualizacion resolverModoVisualizacion(String seccionApiCode) {
  switch (seccionApiCode) {
    case 'AlumnoEspecifico':
    case 'ColaboradorEspecifico':
      return ModoVisualizacion.individual;
    case 'AlumnosSalon':
    case 'Alumnos':
    case 'Colaboradores':
      return ModoVisualizacion.grupoEspecifico;
    case 'AlumnosNivelEdu':
      return ModoVisualizacion.nivelEducativo;
    case 'Todos':
    default:
      return ModoVisualizacion.general;
  }
}