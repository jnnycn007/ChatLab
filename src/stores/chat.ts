import { defineStore } from 'pinia'
import { ref } from 'vue'

export interface ChatSession {
  id: string
  name: string
  avatar?: string
  lastMessage?: string
  timestamp: number
}

export const useChatStore = defineStore(
  'chat',
  () => {
    const sessions = ref<ChatSession[]>([])
    const currentSessionId = ref<string | null>(null)

    function addSession(session: ChatSession) {
      sessions.value.push(session)
      currentSessionId.value = session.id
    }

    function removeSession(id: string) {
      const index = sessions.value.findIndex((s) => s.id === id)
      if (index !== -1) {
        sessions.value.splice(index, 1)
        if (currentSessionId.value === id) {
          currentSessionId.value = null
        }
      }
    }

    function selectSession(id: string) {
      currentSessionId.value = id
    }

    return {
      sessions,
      currentSessionId,
      addSession,
      removeSession,
      selectSession,
    }
  },
  {
    persist: true,
  },
)
