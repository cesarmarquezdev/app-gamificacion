use std::{fs, io::ErrorKind, path::PathBuf};
use tauri::Manager;

// El progreso vive en un solo archivo JSON dentro de la carpeta de datos de la app.
fn state_file(app: &tauri::AppHandle) -> Result<PathBuf, String> {
    let dir = app.path().app_data_dir().map_err(|e| e.to_string())?;
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    Ok(dir.join("estado.json"))
}

#[tauri::command]
fn load_state(app: tauri::AppHandle) -> Result<Option<String>, String> {
    match fs::read_to_string(state_file(&app)?) {
        Ok(s) => Ok(Some(s)),
        Err(e) if e.kind() == ErrorKind::NotFound => Ok(None),
        Err(e) => Err(e.to_string()),
    }
}

#[tauri::command]
fn save_state(app: tauri::AppHandle, json: String) -> Result<(), String> {
    // Nunca pisamos el archivo con algo que no sea JSON válido.
    serde_json::from_str::<serde_json::Value>(&json).map_err(|e| e.to_string())?;
    let file = state_file(&app)?;
    // Escribe a un temporal y renombra: si se corta a medias, no se pierde el progreso anterior.
    let tmp = file.with_extension("tmp");
    fs::write(&tmp, json).map_err(|e| e.to_string())?;
    fs::rename(&tmp, &file).map_err(|e| e.to_string())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![load_state, save_state])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
