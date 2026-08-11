from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CargaViewSet, CandidaturaViewSet

router = DefaultRouter()
router.register(r'cargas', CargaViewSet, basename='cargas')
router.register(r'candidaturas', CandidaturaViewSet, basename='candidaturas')

urlpatterns = [
    path('', include(router.urls)),
]