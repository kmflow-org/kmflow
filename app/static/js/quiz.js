// static/js/quiz.js

document.addEventListener("DOMContentLoaded", function () {
    document.getElementById("submitQuiz").addEventListener("click", function () {
        submitQuiz();
    });

    function submitQuiz() {
        let form = document.getElementById('quizForm');
        let formData = new FormData(form);
        let quizData = {};

        formData.forEach(function(value, key) {
            if (!quizData[key]) {
                quizData[key] = [];
            }
            quizData[key].push(value);
        });

        // Convert the quizData object to JSON.
        let jsonData = JSON.stringify(quizData);

        // Make the AJAX request.
        fetch('/evaluate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: jsonData
        })
        .then(response => response.json())
        .then(data => {
            console.log('Success:', data);
            // You can handle the response data here.
            alert('Quiz submitted successfully!');
        })
        .catch((error) => {
            console.error('Error:', error);
            alert('An error occurred while submitting the quiz.');
        });
    }
});
