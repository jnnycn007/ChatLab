<script setup lang="ts">
defineProps<{
  text?: string
  height?: string
}>()
</script>

<template>
  <div class="flex items-center justify-center" :class="height || 'py-8'">
    <div class="flex flex-col items-center justify-center text-center">
      <UIcon name="i-heroicons-arrow-path" class="h-6 w-6 animate-spin text-pink-500" />
      <p v-if="text" class="mt-2 text-sm text-gray-500">{{ text }}</p>
    </div>
  </div>
</template>
