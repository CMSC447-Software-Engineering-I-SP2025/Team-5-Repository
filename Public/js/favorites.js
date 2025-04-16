function toggleFavorite(event, movieId) {
    event.preventDefault();
    event.stopPropagation();

    const button = event.currentTarget;
    
    // Check if authentication is required
    if (button.dataset.requiresAuth) {
        showAuthModal();
        return;
    }

    // Send request to toggle favorite status
    fetch(`/api/movies/${movieId}/favorite`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.json();
    })
    .then(data => {
        // Update the button appearance
        const icon = button.querySelector('i');
        const text = button.querySelector('span');
        
        if (data.isFavorited) {
            icon.classList.remove('fa-heart-o');
            icon.classList.add('fa-heart');
            icon.classList.add('text-red-500');
            if (text) {
                text.textContent = 'Remove from Favorites';
            }
        } else {
            icon.classList.add('fa-heart-o');
            icon.classList.remove('fa-heart');
            icon.classList.remove('text-red-500');
            if (text) {
                text.textContent = 'Add to Favorites';
            }
        }
    })
    .catch(error => {
        console.error('Error:', error);
        showErrorToast('Failed to update favorite status');
    });
}

function showAuthModal() {
    // Create modal
    const modal = document.createElement('div');
    modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50';
    modal.innerHTML = `
        <div class="bg-white p-6 rounded-lg shadow-xl max-w-md w-full mx-4">
            <h2 class="text-xl font-bold mb-4">Authentication Required</h2>
            <p class="mb-6">You need to be logged in to favorite movies.</p>
            <div class="flex justify-end gap-4">
                <button onclick="closeAuthModal()" class="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300 transition-colors">
                    Cancel
                </button>
                <a href="/login" class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors">
                    Log In
                </a>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
}

function closeAuthModal() {
    const modal = document.querySelector('.fixed.inset-0');
    if (modal) {
        modal.remove();
    }
}

function showErrorToast(message) {
    const toast = document.createElement('div');
    toast.className = 'fixed bottom-4 right-4 bg-red-500 text-white px-6 py-3 rounded shadow-lg transition-opacity duration-300';
    toast.textContent = message;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
        toast.style.opacity = '0';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
} 