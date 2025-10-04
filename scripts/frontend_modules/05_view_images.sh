#!/bin/bash
generate_view_images() {
cat <<'EOF'
                <div data-view-content="images" class="view-content hidden">
                    <h2 class="text-3xl font-bold mb-6">Image Management</h2>
                    <div class="bg-white p-6 rounded-lg shadow">
                        <div class="mb-4 p-4 bg-blue-50 border-l-4 border-blue-400 text-blue-700">
                            <p class="font-bold">Инфо</p>
                            <p>Този панел показва файловете в <strong>/srv/pxeboss/images</strong>. За да добавиш нов образ, качи .vmdk или .qcow2 файл в тази директория и използвай бутона "Convert Cmd", за да видиш командата за конвертиране към .img формат.</p>
                        </div>
                        <div class="overflow-x-auto">
                            <table class="min-w-full divide-y divide-gray-200">
                                <thead class="bg-gray-50">
                                    <tr>
                                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Filename</th>
                                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Size (MB)</th>
                                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Last Modified</th>
                                        <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                                    </tr>
                                </thead>
                                <tbody id="images-table" class="bg-white divide-y divide-gray-200">
                                    </tbody>
                            </table>
                        </div>
                    </div>
                </div>
EOF
}