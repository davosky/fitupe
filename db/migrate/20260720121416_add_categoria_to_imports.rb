class AddCategoriaToImports < ActiveRecord::Migration[8.1]
  def change
    # Imports::SchemaSyncService adds columns dynamically per CSV header
    # outside of migrations, so this column may already exist in an
    # environment where a "Categoria" (rather than "Categoria Sindacale")
    # export was already imported.
    add_column :imports, :categoria, :string unless column_exists?(:imports, :categoria)
  end
end
