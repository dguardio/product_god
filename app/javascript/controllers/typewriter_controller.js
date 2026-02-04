import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.text = this.element.textContent.trim()
        this.element.textContent = ""
        this.index = 0
        this.speed = 10 // Base speed in ms

        this.type()
    }

    type() {
        if (this.index < this.text.length) {
            this.element.textContent += this.text.charAt(this.index)
            this.index++

            // Add slight randomness to typing speed for more natural feel
            const randomDelay = Math.random() * 20

            // Pause slightly on punctuation
            const char = this.text.charAt(this.index - 1)
            let pause = 0
            if (char === '.' || char === '?' || char === '!') pause = 300
            if (char === ',') pause = 100

            setTimeout(() => this.type(), this.speed + randomDelay + pause)
        } else {
            this.dispatch("end")
        }
    }
}
