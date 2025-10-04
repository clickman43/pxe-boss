#!/bin/bash
generate_footer_and_js() {
cat <<'EOF'
                <div data-view-content="admin" class="view-content hidden"><h2 class="text-3xl font-bold mb-6">Admin / Settings</h2><p>Тук ще се управляват глобалните настройки.</p></div>
            </main>
        </div>
    </div>
    <div id="client-modal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full hidden z-50">...</div>
    
    <div id="command-modal" class="fixed inset-0 bg-gray-600 bg-opacity-50 h-full w-full hidden z-50">
        <div class="relative top-20 mx-auto p-5 border w-full max-w-2xl shadow-lg rounded-md bg-white">
            <div class="mt-3">
                <h3 class="text-lg font-medium text-gray-900">Conversion Command</h3>
                <p class="text-sm text-gray-500 mt-2">Копирай тази команда и я изпълни в терминала на сървъра.</p>
                <div class="mt-4">
                    <textarea id="command-text" readonly class="w-full h-24 p-2 font-mono text-sm bg-gray-100 rounded border border-gray-300"></textarea>
                </div>
                <div class="mt-4 text-right">
                    <button id="close-command-modal" class="px-4 py-2 bg-gray-500 text-white text-base font-medium rounded-md hover:bg-gray-600">Close</button>
                </div>
            </div>
        </div>
    </div>

    <script>
    document.addEventListener('DOMContentLoaded', () => {
        // ... (всички дефиниции до тук остават същите) ...
        const commandModal = document.getElementById('command-modal');
        
        // ... (функциите updateDashboardData, renderClientsPage, openClientModal остават същите) ...

        // НОВА функция за страница "Images"
        async function renderImagesPage() {
            const tableBody = document.getElementById('images-table');
            tableBody.innerHTML = '<tr><td colspan="4" class="px-6 py-4 text-center text-gray-500">Loading images...</td></tr>';
            try {
                const images = await fetchWithAuth('/api/images');
                tableBody.innerHTML = '';
                if (images.length === 0) {
                    tableBody.innerHTML = '<tr><td colspan="4" class="px-6 py-4 text-center text-gray-500">No image files found in /srv/pxeboss/images.</td></tr>';
                    return;
                }
                images.forEach(img => {
                    let command = '# Raw .img file. No conversion needed.';
                    const ext = img.name.split('.').pop().toLowerCase();
                    if (['vmdk', 'qcow2'].includes(ext)) {
                        const newName = img.name.replace(`.${ext}`, '.img');
                        command = `qemu-img convert -p -f ${ext} -O raw /srv/pxeboss/images/${img.name} /srv/pxeboss/images/${newName}`;
                    }
                    tableBody.innerHTML += `<tr>
                        <td class="px-6 py-4 font-mono">${img.name}</td>
                        <td class="px-6 py-4">${img.size_mb.toFixed(2)}</td>
                        <td class="px-6 py-4">${new Date(img.modified_date).toLocaleString()}</td>
                        <td class="px-6 py-4 text-right">
                            <button class="show-command-btn font-medium text-blue-600 hover:text-blue-800" data-command="${command}">Convert Cmd</button>
                        </td>
                    </tr>`;
                });
            } catch(error) {
                tableBody.innerHTML = `<tr><td colspan="4" class="px-6 py-4 text-center text-red-500">Error: ${error.message}</td></tr>`;
            }
        }

        // --- Event Listeners ---
        // ... (event listeners за client form и таблиците остават същите) ...
        document.getElementById('images-table').addEventListener('click', (e) => {
            if (e.target.classList.contains('show-command-btn')) {
                document.getElementById('command-text').value = e.target.dataset.command;
                commandModal.classList.remove('hidden');
            }
        });
        document.getElementById('close-command-modal').addEventListener('click', () => {
            commandModal.classList.add('hidden');
        });

        // --- Навигация и инициализация ---
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault(); const view = e.currentTarget.dataset.view;
                // ... (кодът за смяна на активен таб и скриване на страници е същият) ...
                
                if(view === 'dashboard') updateDashboardData();
                if(view === 'clients') renderClientsPage();
                if(view === 'images') renderImagesPage(); // <<< ДОБАВЕН РЕД
            });
        });
        
        // ... (останалият код за logout и setInterval е същият) ...
    });
    </script>
</body>
</html>
EOF
}