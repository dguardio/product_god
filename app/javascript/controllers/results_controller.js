import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["section"]

    connect() {
        this.sectionTargets.forEach(el => {
            el.classList.add("opacity-0", "translate-y-4")
            el.classList.add("transition-all", "duration-700", "ease-out")
        })
    }

    reveal() {
        this.sectionTargets.forEach((el, index) => {
            setTimeout(() => {
                el.classList.remove("opacity-0", "translate-y-4")
            }, index * 200) // Stagger the reveal
        })
    }
}
